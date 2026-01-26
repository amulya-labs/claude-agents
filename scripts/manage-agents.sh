#!/bin/bash
set -e

# Claude Agents Manager
# Copy this script to your project and use it to install/update agents
#
# Usage:
#   ./scripts/manage-agents.sh install   # First-time setup
#   ./scripts/manage-agents.sh update    # Pull latest agents

REPO="rrlamichhane/claude-agents"
BRANCH="main"
AGENTS_DIR=".claude/agents"
API_URL="https://api.github.com/repos/$REPO/contents/.claude/agents?ref=$BRANCH"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/agents"

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

# Fetch list of agent files from GitHub API
get_agent_files() {
    local response
    response=$(curl -fsSL "$API_URL" 2>/dev/null) || {
        error "Failed to fetch agent list from GitHub API"
    }

    # Extract .md filenames from JSON response
    # Works without jq by using grep and sed
    echo "$response" | grep -o '"name": *"[^"]*\.md"' | sed 's/"name": *"\([^"]*\)"/\1/'
}

download_agents() {
    mkdir -p "$AGENTS_DIR"

    info "Fetching agent list from GitHub..."
    local agents
    agents=$(get_agent_files)

    if [ -z "$agents" ]; then
        error "No agent files found"
    fi

    local success=0
    local failed=0

    while IFS= read -r agent; do
        local url="$RAW_BASE/$agent"
        local dest="$AGENTS_DIR/$agent"

        if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
            info "Downloaded $agent"
            ((success++))
        else
            warn "Failed to download $agent"
            ((failed++))
        fi
    done <<< "$agents"

    echo ""
    info "Downloaded $success agents"

    if [ $failed -gt 0 ]; then
        warn "$failed agents failed to download"
    fi
}

install_agents() {
    check_git

    if [ -d "$AGENTS_DIR" ] && [ "$(ls -A "$AGENTS_DIR" 2>/dev/null)" ]; then
        error "Directory $AGENTS_DIR already exists and is not empty. Use 'update' instead."
    fi

    info "Installing claude-agents to $AGENTS_DIR..."
    download_agents

    git add "$AGENTS_DIR"

    info "Done! Agents installed to $AGENTS_DIR"
    echo ""
    echo "Next steps:"
    echo "  git commit -m 'Add claude-agents'"
    echo "  git push"
}

update_agents() {
    check_git

    if [ ! -d "$AGENTS_DIR" ]; then
        error "Directory $AGENTS_DIR not found. Use 'install' first."
    fi

    info "Updating claude-agents..."
    download_agents

    git add "$AGENTS_DIR"

    info "Done! Agents updated."
    echo ""
    echo "Next steps:"
    echo "  git diff --cached  # review changes"
    echo "  git commit -m 'Update claude-agents'"
    echo "  git push"
}

case "${1:-}" in
    install)
        install_agents
        ;;
    update)
        update_agents
        ;;
    *)
        echo "Claude Agents Manager"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  install   Add claude-agents to your project (first-time setup)"
        echo "  update    Pull the latest agents"
        exit 1
        ;;
esac
