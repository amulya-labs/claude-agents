#!/bin/bash
# Claude Code PreToolUse hook for Bash command validation
# Validates commands against patterns defined in bash-patterns.toml
# Handles command combinations (pipes, chains, subshells)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/bash-patterns.toml"

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Use Python for TOML parsing and validation
exec python3 "$SCRIPT_DIR/validate-bash.py" "$CONFIG_FILE"
