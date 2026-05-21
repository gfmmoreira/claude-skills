#!/bin/bash
set -e

SKILL_DIR="${HOME}/.claude/skills/skill-evolver"
COMMANDS_DIR="${HOME}/.claude/commands"
BASE_URL="https://raw.githubusercontent.com/gfmmoreira/claude-skills/develop"

echo "Installing skill-evolver..."

mkdir -p "${SKILL_DIR}"
mkdir -p "${COMMANDS_DIR}"

curl -fsSL "${BASE_URL}/skill-evolver/SKILL.md" -o "${SKILL_DIR}/SKILL.md"
curl -fsSL "${BASE_URL}/skill-evolver/scan.sh" -o "${SKILL_DIR}/scan.sh"
chmod +x "${SKILL_DIR}/scan.sh"

cat > "${COMMANDS_DIR}/skill-evolver.md" << 'EOF'
Run skill-evolver: read my Claude Code transcripts, find where I corrected Claude, and propose rule changes based on what actually went wrong.

Steps:
1. Run `~/.claude/skills/skill-evolver/scan.sh --days $ARGUMENTS` (default 30 if no argument given) and capture the evidence file path from stdout
2. Follow the full SKILL.md at `~/.claude/skills/skill-evolver/SKILL.md`
EOF

echo "Done. Use it with: /skill-evolver or /skill-evolver 90"
