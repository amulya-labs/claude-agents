#!/bin/bash
# Claude Code PreToolUse hook for Bash command validation
# Validates commands against patterns defined in bash-patterns.toml
# Handles command combinations (pipes, chains, subshells)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/bash-patterns.toml"

# Logging setup
LOG_DIR="/tmp/claude-hook-logs"
LOG_FILE="$LOG_DIR/bash-hook-$(date '+%Y-%m-%d').log"
LOG_RETENTION_DAYS=15

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

cleanup_old_logs() {
    find "$LOG_DIR" -name "bash-hook-*.log" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
}

# Cleanup old logs (run in background to not slow down hook)
cleanup_old_logs &

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR: Configuration file not found: $CONFIG_FILE"
    echo "Error: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Capture stdin for logging
INPUT=$(cat)
log "Input: $INPUT"

# Use Python for TOML parsing and validation
OUTPUT=$(echo "$INPUT" | python3 "$SCRIPT_DIR/validate-bash.py" "$CONFIG_FILE" 2>&1) || {
    log "ERROR: Python script failed with exit code $?"
    log "Output: $OUTPUT"
    exit 1
}

log "Output: ${OUTPUT:-<empty/allow>}"
echo "$OUTPUT"
