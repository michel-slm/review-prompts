#!/bin/bash
#
# Claude Code setup for RPM package review
#
# Installs:
#   - rpm skill to ~/.claude/skills/rpm/SKILL.md
#   - Slash commands to ~/.claude/commands/
#
# The prompts directory is determined from this script's location.

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The review-prompts directory is the parent of the scripts directory
PROMPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Review prompts directory: $PROMPTS_DIR"
echo ""

# --- Install Skill ---

SKILL_DIR="$HOME/.claude/skills/rpm"
SKILL_FILE="$SKILL_DIR/SKILL.md"
SOURCE_SKILL="$PROMPTS_DIR/skills/rpm.md"

if [ ! -f "$SOURCE_SKILL" ]; then
    echo "Error: Source skill file not found: $SOURCE_SKILL"
    exit 1
fi

mkdir -p "$SKILL_DIR"

sed "s|{{RPM_REVIEW_PROMPTS_DIR}}|$PROMPTS_DIR|g" "$SOURCE_SKILL" > "$SKILL_FILE"

echo "Installed skill:"
echo "  $SKILL_FILE"

# --- Install Slash Commands ---

COMMANDS_DIR="$HOME/.claude/commands"
SLASH_COMMANDS_SRC="$PROMPTS_DIR/slash-commands"

if [ ! -d "$SLASH_COMMANDS_SRC" ]; then
    echo "Warning: slash-commands directory not found, skipping"
else
    mkdir -p "$COMMANDS_DIR"

    echo ""
    echo "Installed slash commands:"

    for cmd_file in "$SLASH_COMMANDS_SRC"/*.md; do
        if [ -f "$cmd_file" ]; then
            cmd_name=$(basename "$cmd_file")
            sed "s|REVIEW_DIR|$PROMPTS_DIR|g" "$cmd_file" > "$COMMANDS_DIR/$cmd_name"
            echo "  /${cmd_name%.md}"
        fi
    done
fi

echo ""
echo "Setup complete!"
echo ""
echo "Available commands:"
echo "  /rpm-review - Review RPM spec files and packages"
echo "  /rpm-debug  - Debug RPM build failures"
echo "  /rpm-verify - Verify findings against false positive patterns"
echo ""
echo "The RPM skill loads automatically in RPM packaging trees."
