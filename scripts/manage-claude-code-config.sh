#!/bin/bash
set -e

# Claude Code Config Manager
# Copy this script to your project and use it to install/update .claude config
#
# Source: https://github.com/amulya-labs/claude-code-config
# License: MIT (https://opensource.org/licenses/MIT)
#
# Usage:
#   ./scripts/manage-claude-code-config.sh install                        # First-time setup
#   ./scripts/manage-claude-code-config.sh install --with-gha-workflows   # Include Claude GitHub Actions
#   ./scripts/manage-claude-code-config.sh update                         # Pull latest config
#   ./scripts/manage-claude-code-config.sh update --with-gha-workflows    # Update including workflows

REPO="amulya-labs/claude-code-config"
BRANCH="main"
CLAUDE_DIR=".claude"
API_BASE="https://api.github.com/repos/$REPO/contents"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
WITH_GHA_WORKFLOWS=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}==>${NC} $1"; }
error() { echo -e "${RED}==>${NC} $1"; exit 1; }

# Check if we're in a git repo
check_git() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        error "Not inside a git repository"
    fi

    # Make sure we're at repo root
    cd "$(git rev-parse --show-toplevel)"
}

# Fetch list of files from a GitHub directory
get_files_in_dir() {
    local dir="$1"
    local response
    response=$(curl -fsSL "$API_BASE/$dir?ref=$BRANCH" 2>/dev/null) || {
        warn "Failed to fetch file list from $dir"
        return 1
    }

    # Extract filenames from JSON response (works without jq)
    echo "$response" | grep -o '"name": *"[^"]*"' | sed 's/"name": *"\([^"]*\)"/\1/'
}

# Download files from a directory
download_dir() {
    local remote_dir="$1"
    local local_dir="$2"

    mkdir -p "$local_dir"

    info "Fetching $remote_dir..."
    local files
    files=$(get_files_in_dir "$remote_dir") || return 1

    if [ -z "$files" ]; then
        warn "No files found in $remote_dir"
        return 0
    fi

    local success=0
    local failed=0

    while IFS= read -r file; do
        local url="$RAW_BASE/$remote_dir/$file"
        local dest="$local_dir/$file"

        if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
            info "  Downloaded $file"
            ((++success))
        else
            warn "  Failed to download $file"
            ((++failed))
        fi
    done <<< "$files"

    echo "  $success files downloaded"
    if [ $failed -gt 0 ]; then
        warn "  $failed files failed"
    fi
}

download_all() {
    mkdir -p "$CLAUDE_DIR"

    # Download agents
    download_dir ".claude/agents" "$CLAUDE_DIR/agents"

    # Download hooks
    download_dir ".claude/hooks" "$CLAUDE_DIR/hooks"

    # Make hook scripts executable
    if [ -d "$CLAUDE_DIR/hooks" ]; then
        chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
        chmod +x "$CLAUDE_DIR/hooks/"*.py 2>/dev/null || true
    fi

    # Download settings.json
    info "Fetching settings.json..."
    if curl -fsSL "$RAW_BASE/.claude/settings.json" -o "$CLAUDE_DIR/settings.json" 2>/dev/null; then
        info "  Downloaded settings.json"
    else
        warn "  settings.json not found (optional)"
    fi

    # Optionally download GitHub Actions workflows
    if $WITH_GHA_WORKFLOWS; then
        download_gha_workflows
    fi
}

download_gha_workflows() {
    info "Fetching Claude GitHub Actions workflows..."
    download_dir ".github/workflows" ".github/workflows"
    warn "Requires CLAUDE_CODE_OAUTH_TOKEN secret in your repo settings"
}

install_config() {
    check_git

    if [ -d "$CLAUDE_DIR" ] && [ "$(ls -A "$CLAUDE_DIR" 2>/dev/null)" ]; then
        error "Directory $CLAUDE_DIR already exists and is not empty. Use 'update' instead."
    fi

    info "Installing claude-code config to $CLAUDE_DIR..."
    echo ""
    download_all

    git add "$CLAUDE_DIR"
    if $WITH_GHA_WORKFLOWS; then
        git add .github/workflows/ 2>/dev/null || true
    fi

    echo ""
    info "Done! Config installed to $CLAUDE_DIR"
    if $WITH_GHA_WORKFLOWS; then
        info "Claude workflows installed to .github/workflows/"
    fi
    echo ""
    echo "Next steps:"
    echo "  git commit -m 'Add claude-code config'"
    echo "  git push"
}

update_config() {
    check_git

    if [ ! -d "$CLAUDE_DIR" ]; then
        error "Directory $CLAUDE_DIR not found. Use 'install' first."
    fi

    info "Updating claude-code config..."
    echo ""
    download_all

    git add "$CLAUDE_DIR"
    if $WITH_GHA_WORKFLOWS; then
        git add .github/workflows/ 2>/dev/null || true
    fi

    echo ""
    info "Done! Config updated."
    if $WITH_GHA_WORKFLOWS; then
        info "Claude workflows updated in .github/workflows/"
    fi
    echo ""
    echo "Next steps:"
    echo "  git diff --cached  # review changes"
    echo "  git commit -m 'Update claude-code config'"
    echo "  git push"
}

# Parse global flags
shift_args=()
for arg in "$@"; do
    case "$arg" in
        --with-gha-workflows) WITH_GHA_WORKFLOWS=true ;;
        *) shift_args+=("$arg") ;;
    esac
done
set -- "${shift_args[@]}"

case "${1:-}" in
    install)
        install_config
        ;;
    update)
        update_config
        ;;
    *)
        echo "Claude Code Config Manager"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  install   Add .claude config to your project (first-time setup)"
        echo "  update    Pull the latest config (agents, hooks, settings)"
        echo ""
        echo "Options:"
        echo "  --with-gha-workflows   Also install Claude GitHub Actions workflows"
        echo "                         (requires CLAUDE_CODE_OAUTH_TOKEN secret in repo)"
        echo ""
        echo "This downloads:"
        echo "  .claude/agents/   - Reusable Claude Code agents"
        echo "  .claude/hooks/    - PreToolUse hooks (e.g., bash validation)"
        echo "  .claude/settings.json - Hook configuration"
        echo ""
        echo "With --with-gha-workflows, also downloads:"
        echo "  .github/workflows/claude.yml             - @claude mention handler"
        echo "  .github/workflows/claude-code-review.yml - Auto PR review"
        exit 1
        ;;
esac
