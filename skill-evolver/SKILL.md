---
name: skill-evolver
version: 1.0.0
description: "Read your Claude Code transcripts for moments where you corrected or pushed back on Claude, find the recurring failure patterns, and propose concrete rule changes to ~/.claude/CLAUDE.md. Use when asked to self-improve, find failure patterns, or evolve instructions."
argument-hint: "[--days N]"
allowed-tools: Bash Read Write
---

# skill-evolver

You are analyzing your own failure patterns to propose concrete, evidence-backed behavior improvements.

## What you do

1. Run the scanner to extract evidence from real transcripts
2. Read the evidence file
3. Cluster into three root causes only
4. Propose up to 3 upgrades, each with: evidence, patch, and regression prompt
5. Write proposal files — do NOT modify any config files directly

---

## Step 1 — Ensure fresh facets, then run the scanner

First, check whether `~/.claude/usage-data/facets/` exists and contains files modified within the last 24 hours:

```bash
find ~/.claude/usage-data/facets/ -name "*.json" -mtime -1 2>/dev/null | wc -l
```

If the count is 0 (no recent facets), run `/insights` now before continuing. The scanner depends on facets for its primary evidence source — without them it falls back to regex-only detection, which is less accurate.

Once facets are confirmed fresh, run the scanner:

```bash
~/.claude/skills/skill-evolver/scan.sh --days {{days|30}}
```

Read the output path from stdout. Then read the evidence file.

---

## Step 2 — Read current instructions and prior patches

Read `~/.claude/CLAUDE.md` to understand what rules already exist.
Do not propose a rule that is already covered — check for semantic overlap, not just exact wording.

Also list all files in `~/.claude/evolver/proposals/` and read any with `Status: accepted`.
For each accepted proposal, note its root cause and acceptance date — you will use this in Step 3.

---

## Step 3 — Cluster evidence

Group evidence moments into these three root causes only. Discard anything that does not fit cleanly.

| Root cause | What it looks like |
|---|---|
| **fabrication** | User corrects a factual claim Claude made without evidence (field names, file contents, test results, permissions) |
| **premature_tool_use** | User asks for explanation; Claude jumps to tools, searches, or implementation first |
| **instruction_order** | Claude violated an explicit sequencing directive the user stated (wrong repo, wrong language, wrong order) |

Score each cluster:

```
cluster_score =
  (incident_count * 3)
  + (distinct_session_count * 2)
  + (distinct_project_count * 2)
  + (explicit_frustration_phrase_count * 1)
```

Only surface clusters with score >= 6 AND at least 2 incidents. If nothing meets threshold, say so and stop.

For each qualifying cluster, check whether an accepted proposal already targets the same root cause:

- If yes and incidents are still occurring: flag as **rule not holding** — the patch exists but failed. Do not propose the same patch again. Instead, note the recurrence and suggest strengthening or replacing the rule.
- If yes and zero incidents: flag as **rule holding** — skip this cluster, no action needed.
- If no prior patch: proceed normally.

---

## Step 4 — Propose upgrades

For each qualifying cluster (max 3, ordered by score descending):

### Upgrade N: [short name]

**Root cause:** [fabrication | premature_tool_use | instruction_order]

**Evidence** (sanitized):
- Session [first 8 chars of session ID], [project]: "[sanitized quote]"
- Session [first 8 chars], [project]: "[sanitized quote]"
- (list all incidents for this cluster)

**Score:** [N] ([X] incidents, [Y] sessions, [Z] projects)

**Existing rule check:** [Does ~/.claude/CLAUDE.md already cover this? Quote the relevant line if so, and explain why it's still failing.]

**Patch target:** `~/.claude/CLAUDE.md`

**Proposed addition** (<= 10 lines, under the most relevant existing section):

**Regression prompt:**
> [A short prompt that would have triggered this failure. Be specific — generic prompts are useless.]

**Expected behavior with patch:** [One sentence: what Claude should do differently.]

**Recommendation:** Accept / Needs review / Skip (with reason)

---

## Step 5 — Write proposal files

For each upgrade, write a proposal file:

```
~/.claude/evolver/proposals/YYYY-MM-DD-[root-cause-slug].md
```

File format:
```
# Upgrade: [short name]
Date: YYYY-MM-DD
Root cause: [root cause]
Score: [N]
Status: pending

## Evidence
[paste evidence section]

## Patch
[paste diff]

## Regression prompt
[paste prompt]

## Expected behavior
[one sentence]
```

Then write a summary report to `~/.claude/evolver/reports/YYYY-MM-DD-summary.md`.

---

## Step 6 — Present to user

Show each upgrade in the format from Step 4. End with:

```
Proposal files written to ~/.claude/evolver/proposals/
To apply a patch: open the file, copy the diff, paste into ~/.claude/CLAUDE.md
```

Do not apply any patch automatically. The user decides what to accept.

---

## What NOT to do

- Do not modify `~/.claude/CLAUDE.md` or any skill file directly
- Do not propose more than 3 upgrades
- Do not surface clusters with fewer than 2 incidents
- Do not propose a rule already covered by existing CLAUDE.md content
- Do not invent evidence — only use what the scanner found
- Do not hallucinate session IDs, quotes, or project names
