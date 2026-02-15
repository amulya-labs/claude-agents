#!/bin/bash
# Claude Code PreToolUse hook for Bash command validation
# Validates commands against patterns defined in bash-patterns.toml
# Handles command combinations (pipes, chains, subshells)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/bash-patterns.toml"

# Logging setup (only logs ask/deny decisions to reduce disk I/O)
LOG_DIR="/tmp/claude-hook-logs"
LOG_RETENTION_DAYS=15

mkdir -p "$LOG_DIR"

cleanup_old_logs() {
    find "$LOG_DIR" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
}

# Cleanup old logs (run in background to not slow down hook)
cleanup_old_logs &

# Check config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    # Use fallback log file for config errors
    LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d')-error.log"
    {
        echo "========================================"
        echo "TIME:   $(date '+%Y-%m-%d %H:%M:%S')"
        echo "ERROR:  Configuration file not found"
        echo "PATH:   $CONFIG_FILE"
        echo "========================================"
    } >> "$LOG_FILE"
    echo "Error: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Capture stdin
INPUT=$(cat)

# Extract project name from cwd for log filename
PROJECT=$(echo "$INPUT" | python3 -c "
import sys, json, os
try:
    data = json.load(sys.stdin)
    cwd = data.get('cwd', '')
    print(os.path.basename(cwd) if cwd else 'unknown')
except:
    print('unknown')
" 2>/dev/null)

# Log filename: YYYY-MM-DD-Day-project.log (sorts chronologically)
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d-%a')-${PROJECT}.log"

# Use Python for TOML parsing and validation
OUTPUT=$(echo "$INPUT" | python3 "$SCRIPT_DIR/validate-bash.py" "$CONFIG_FILE" 2>&1) || {
    COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command','<unknown>'))" 2>/dev/null || echo "<parse error>")
    {
        echo "========================================"
        echo "TIME:   $(date '+%Y-%m-%d %H:%M:%S')"
        echo "ERROR:  Python script failed"
        echo "CMD:    $COMMAND"
        echo "OUTPUT: $OUTPUT"
        echo "========================================"
    } >> "$LOG_FILE"
    exit 1
}

# Only log ask/deny decisions (not allow) to reduce disk I/O
if echo "$OUTPUT" | grep -q '"permissionDecision": *"deny"'; then
    COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
    REASON=$(echo "$OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hookSpecificOutput',{}).get('permissionDecisionReason',''))" 2>/dev/null)
    {
        echo "========================================"
        echo "TIME:   $(date '+%Y-%m-%d %H:%M:%S')"
        echo "ACTION: DENY"
        echo "REASON: $REASON"
        echo "CMD:    $COMMAND"
        echo "========================================"
    } >> "$LOG_FILE"
elif echo "$OUTPUT" | grep -q '"permissionDecision": *"ask"'; then
    COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
    REASON=$(echo "$OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hookSpecificOutput',{}).get('permissionDecisionReason',''))" 2>/dev/null)
    {
        echo "========================================"
        echo "TIME:   $(date '+%Y-%m-%d %H:%M:%S')"
        echo "ACTION: ASK"
        echo "REASON: $REASON"
        echo "CMD:    $COMMAND"
        echo "========================================"
    } >> "$LOG_FILE"
fi

echo "$OUTPUT"
