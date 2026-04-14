#!/bin/bash
set -e

SKILLS_DIR="${HOME}/.claude/skills/1on1-coach"
BASE_URL="https://raw.githubusercontent.com/gfmmoreira/claude-skills/develop"

echo "Installing 1on1-coach..."

mkdir -p "${SKILLS_DIR}/references"

curl -fsSL "${BASE_URL}/1on1-coach/SKILL.md" -o "${SKILLS_DIR}/SKILL.md"
curl -fsSL "${BASE_URL}/1on1-coach/references/reality-check.md" -o "${SKILLS_DIR}/references/reality-check.md"
curl -fsSL "${BASE_URL}/1on1-coach/references/framing-by-role.md" -o "${SKILLS_DIR}/references/framing-by-role.md"

echo "Done. Use it with: /1on1-coach [person name]"
