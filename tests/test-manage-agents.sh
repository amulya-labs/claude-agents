#!/bin/bash
# Tests for manage-claude-code-config.sh — verifies workflow templates are distributed
# correctly (sourced from .github/workflows/).
#
# Source: https://github.com/amulya-labs/claude-code-config
# License: MIT (https://opensource.org/licenses/MIT)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANAGE_SCRIPT="$REPO_ROOT/scripts/manage-claude-code-config.sh"

PASS=0
FAIL=0
ERRORS=()

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    NC=''
fi

assert() {
    local desc="$1"
    local result="$2"  # "pass" or "fail"
    local detail="${3:-}"

    if [[ "$result" == "pass" ]]; then
        echo -e "  ${GREEN}✓${NC} $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $desc"
        [[ -n "$detail" ]] && echo "    $detail"
        ERRORS+=("$desc")
        FAIL=$((FAIL + 1))
    fi
}

# ── Repo layout checks ─────────────────────────────────────────────

echo "=== Workflow file locations ==="

EXPECTED_WORKFLOWS=(claude.yml claude-code-review.yml)

for f in "${EXPECTED_WORKFLOWS[@]}"; do
    if [[ -f "$REPO_ROOT/.github/workflows/$f" ]]; then
        assert ".github/workflows/$f exists" "pass"
    else
        assert ".github/workflows/$f exists" "fail" "File not found"
    fi
done

# gha-workflow-templates/ should no longer exist
if [[ ! -d "$REPO_ROOT/gha-workflow-templates" ]]; then
    assert "gha-workflow-templates/ directory removed" "pass"
else
    assert "gha-workflow-templates/ directory removed" "fail" \
        "Directory should be removed — workflows now live in .github/workflows/"
fi

echo

# ── manage-claude-code-config.sh script checks ─────────────────────

echo "=== manage-claude-code-config.sh flag and function checks ==="

# shellcheck disable=SC2310
if grep -q 'WITH_GHA_WORKFLOWS=false' "$MANAGE_SCRIPT"; then
    assert "Default variable is WITH_GHA_WORKFLOWS" "pass"
else
    assert "Default variable is WITH_GHA_WORKFLOWS" "fail" \
        "Expected WITH_GHA_WORKFLOWS=false in script"
fi

if grep -q -- '--with-gha-workflows)' "$MANAGE_SCRIPT"; then
    assert "Flag --with-gha-workflows is recognized" "pass"
else
    assert "Flag --with-gha-workflows is recognized" "fail"
fi

if ! grep -q -- '--with-workflows)' "$MANAGE_SCRIPT"; then
    assert "Old flag --with-workflows is removed" "pass"
else
    assert "Old flag --with-workflows is removed" "fail" \
        "Found stale --with-workflows reference"
fi

if grep -q 'download_gha_workflows()' "$MANAGE_SCRIPT"; then
    assert "Function download_gha_workflows() exists" "pass"
else
    assert "Function download_gha_workflows() exists" "fail"
fi

if ! grep -q 'download_workflows()' "$MANAGE_SCRIPT"; then
    assert "Old function download_workflows() is removed" "pass"
else
    assert "Old function download_workflows() is removed" "fail" \
        "Found stale download_workflows() definition"
fi

echo

# ── download_gha_workflows path mapping ─────────────────────────────

echo "=== download_gha_workflows path mapping ==="

# The function should call download_dir with remote=.github/workflows, local=.github/workflows
if grep -q 'download_dir ".github/workflows" ".github/workflows"' "$MANAGE_SCRIPT"; then
    assert "download_gha_workflows maps .github/workflows → .github/workflows" "pass"
else
    assert "download_gha_workflows maps .github/workflows → .github/workflows" "fail" \
        "Expected: download_dir \".github/workflows\" \".github/workflows\""
fi

echo

# ── shellcheck ──────────────────────────────────────────────────────

echo "=== shellcheck ==="

if command -v shellcheck &>/dev/null; then
    if shellcheck "$MANAGE_SCRIPT" 2>&1; then
        assert "manage-claude-code-config.sh passes shellcheck" "pass"
    else
        assert "manage-claude-code-config.sh passes shellcheck" "fail"
    fi
else
    echo "  (shellcheck not installed — skipping)"
fi

echo

# ── Summary ─────────────────────────────────────────────────────────

echo "=== Summary ==="
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"

if [[ $FAIL -gt 0 ]]; then
    echo
    echo "Failures:"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    exit 1
fi

echo -e "\n${GREEN}All tests passed!${NC}"
