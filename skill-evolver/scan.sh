#!/usr/bin/env zsh
# Scans Claude Code session data for correction/frustration moments.
#
# Primary source: ~/.claude/usage-data/facets/ (pre-classified by /insights)
# Secondary source: ~/.claude/projects/ raw JSONL transcripts (regex fallback)
#
# Usage: scan.sh [--days N] [--out path]

set -uo pipefail

DAYS=30
OUT_DIR="$HOME/.claude/evolver/raw"
TODAY=$(date +%Y-%m-%d)
OUT_FILE="$OUT_DIR/evidence-$TODAY.jsonl"
FACETS_DIR="$HOME/.claude/usage-data/facets"
SESSION_META_DIR="$HOME/.claude/usage-data/session-meta"
PROJECTS_DIR="$HOME/.claude/projects"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --out)  OUT_FILE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$OUT_DIR"

# Cutoff timestamp (seconds since epoch)
CUTOFF=$(date -v -"${DAYS}"d +%s 2>/dev/null || date -d "-${DAYS} days" +%s)

map_friction_to_root_cause() {
  local key="$1"
  case "$key" in
    fabricated_information|inaccurate_claim|unfounded_speculation)
      echo "fabrication" ;;
    misunderstood_request|violated_user_preference|premature_assumptions)
      echo "instruction_order" ;;
    wrong_approach|user_rejected_action|excessive_changes)
      echo "other_frustration" ;;
    *)
      echo "" ;;
  esac
}

FACETS_COUNT=0
declare -A seen_sessions

if [[ -d "$FACETS_DIR" ]]; then
  for facet_file in "$FACETS_DIR"/*.json; do
    [[ -f "$facet_file" ]] || continue

    file_mtime=$(stat -f %m "$facet_file" 2>/dev/null || stat -c %Y "$facet_file" 2>/dev/null)
    [[ "$file_mtime" -lt "$CUTOFF" ]] && continue

    session_id=$(jq -r '.session_id // empty' "$facet_file" 2>/dev/null)
    [[ -z "$session_id" ]] && session_id=$(basename "$facet_file" .json)

    has_friction=$(jq -r '
      (.friction_counts // {} | to_entries | map(select(.value > 0)) | length) > 0
      or
      ((.user_satisfaction_counts.dissatisfied // 0) > 0)
    ' "$facet_file" 2>/dev/null)
    [[ "$has_friction" != "true" ]] && continue

    project=""
    for project_dir in "$PROJECTS_DIR"/*/; do
      if [[ -f "$project_dir${session_id}.jsonl" ]]; then
        project=$(basename "$project_dir")
        break
      fi
    done

    friction_detail=$(jq -r '.friction_detail // ""' "$facet_file" 2>/dev/null)
    outcome=$(jq -r '.outcome // ""' "$facet_file" 2>/dev/null)
    summary=$(jq -r '.brief_summary // ""' "$facet_file" 2>/dev/null)

    while IFS="=" read -r key count; do
      [[ -z "$key" || "$count" -lt 1 ]] && continue

      root_cause=$(map_friction_to_root_cause "$key")
      [[ -z "$root_cause" ]] && continue

      dedup_key="${session_id}:${root_cause}"
      [[ -n "${seen_sessions[$dedup_key]:-}" ]] && continue
      seen_sessions[$dedup_key]=1

      jq -n \
        --arg source "facets" \
        --arg project "$project" \
        --arg session "$session_id" \
        --arg friction_key "$key" \
        --arg root_cause "$root_cause" \
        --arg friction_detail "$friction_detail" \
        --arg outcome "$outcome" \
        --arg summary "$summary" \
        '{
          source: $source,
          project: $project,
          session: $session,
          friction_key: $friction_key,
          root_cause: $root_cause,
          friction_detail: $friction_detail,
          outcome: $outcome,
          summary: $summary
        }' >> "$OUT_FILE"

      FACETS_COUNT=$((FACETS_COUNT + 1))

    done < <(jq -r '(.friction_counts // {}) | to_entries[] | "\(.key)=\(.value)"' "$facet_file" 2>/dev/null)
  done
fi

# PERSONALIZE THESE: the phrases below are tuned to one user's vocabulary.
# Replace or extend with your own correction/frustration phrases.
FRUSTRATION_RE="that'?s a lie|cut that crap|you invented|what do you mean you invented|quite shit|you didn'?t check|you never (checked|read|ran|opened)|stop doing|don'?t do that|no[,.]? i (want|asked|said|need)|i said|i asked for"

# General negative sentiment signals (source: github.com/alex000kim/claude-code)
NEGATIVE_RE="wtf|wth|ffs|omfg|shit(ty|tiest)?|dumbass|horrible|awful|piss(ed|ing)? off|piece of (shit|crap|junk)|what the (fuck|hell)|fucking? (broken|useless|terrible|awful|horrible)|fuck you|screw (this|you)|so frustrating|this sucks|damn it"
CORRECTION_RE="actually[,.]? (it|that|you)|you missed|you (skipped|ignored|forgot)|that'?s not what|you're wrong|that'?s wrong"
ORDER_RE="explain (first|before|it first)|concept(ual)? (first|before)|don'?t (search|read|use|open|launch|run) (yet|first|before)|i (just )?wanted (you to )?explain|before (you )?implement|no tools"

RAW_COUNT=0

for project_dir in "$PROJECTS_DIR"/*/; do
  project=$(basename "$project_dir")

  for transcript in "$project_dir"*.jsonl; do
    [[ -f "$transcript" ]] || continue

    file_mtime=$(stat -f %m "$transcript" 2>/dev/null || stat -c %Y "$transcript" 2>/dev/null)
    [[ "$file_mtime" -lt "$CUTOFF" ]] && continue

    session_id=$(basename "$transcript" .jsonl)
    [[ -f "$FACETS_DIR/${session_id}.json" ]] && continue

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue

      msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
      [[ "$msg_type" != "user" ]] && continue

      text=$(echo "$line" | jq -r '.message.content[]? | select(.type == "text") | .text' 2>/dev/null | tr '\n' ' ')
      [[ -z "$text" ]] && continue

      text_length=${#text}
      has_code_block=$(echo "$text" | grep -c '```' 2>/dev/null || true)
      has_system_marker=$(echo "$text" | grep -cE 'system-reminder|<command-message>|The user just ran /' 2>/dev/null || true)
      [[ "$has_code_block" -gt 0 && "$text_length" -gt 500 ]] && continue
      [[ "$has_system_marker" -gt 0 ]] && continue

      lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

      root_cause=""
      if echo "$lower_text" | grep -qiE "lie|invented|you (said|claimed)|you didn'?t check|you never"; then
        root_cause="fabrication"
      elif echo "$lower_text" | grep -qiE "$ORDER_RE"; then
        root_cause="instruction_order"
      elif echo "$lower_text" | grep -qiE "$FRUSTRATION_RE|$CORRECTION_RE|$NEGATIVE_RE"; then
        root_cause="other_frustration"
      fi
      [[ -z "$root_cause" ]] && continue

      dedup_key="${session_id}:${root_cause}"
      [[ -n "${seen_sessions[$dedup_key]:-}" ]] && continue
      seen_sessions[$dedup_key]=1

      sanitized=$(echo "$text" | sed -E \
        "s/that'?s a lie/[correction: factual dispute]/gi;
         s/cut that crap/[correction: rejected output]/gi;
         s/quite shit/[correction: quality rejection]/gi;
         s/\bwtf\b/[frustration]/gi" \
      )

      timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)

      jq -n \
        --arg source "raw_transcript" \
        --arg project "$project" \
        --arg session "$session_id" \
        --arg root_cause "$root_cause" \
        --arg friction_detail "$sanitized" \
        --arg timestamp "$timestamp" \
        '{
          source: $source,
          project: $project,
          session: $session,
          root_cause: $root_cause,
          friction_detail: $friction_detail,
          timestamp: $timestamp
        }' >> "$OUT_FILE"

      RAW_COUNT=$((RAW_COUNT + 1))

    done < "$transcript"
  done
done

TOTAL=$((FACETS_COUNT + RAW_COUNT))
echo "Scanned $DAYS days. Found $TOTAL moments ($FACETS_COUNT from facets, $RAW_COUNT from raw transcripts)." >&2
echo "Evidence written to: $OUT_FILE" >&2
echo "$OUT_FILE"
