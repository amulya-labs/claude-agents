#!/bin/bash
set -e

# Claude Agents Manager
# Copy this script to your project and use it to install/update agents
#
# Usage:
#   ./scripts/manage-agents.sh install   # First-time setup
#   ./scripts/manage-agents.sh update    # Pull latest agents

REPO_URL="https://github.com/rrlamichhane/claude-agents.git"
AGENTS_PREFIX=".claude/agents"
BRANCH="main"

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

install_agents() {
    check_git

    if [ -d "$AGENTS_PREFIX" ]; then
        error "Directory $AGENTS_PREFIX already exists. Use 'update' instead."
    fi

    info "Installing claude-agents to $AGENTS_PREFIX..."

    git subtree add --prefix="$AGENTS_PREFIX" "$REPO_URL" "$BRANCH" --squash

    info "Done! Agents installed to $AGENTS_PREFIX"
    echo ""
    echo "Next steps:"
    echo "  git push"
}

update_agents() {
    check_git

    if [ ! -d "$AGENTS_PREFIX" ]; then
        error "Directory $AGENTS_PREFIX not found. Use 'install' first."
    fi

    info "Updating claude-agents..."

    git subtree pull --prefix="$AGENTS_PREFIX" "$REPO_URL" "$BRANCH" --squash

    info "Done! Agents updated."
    echo ""
    echo "Next steps:"
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
