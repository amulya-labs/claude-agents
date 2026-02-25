#!/bin/bash
# Tests for manage-agents.sh — verifies workflow templates are distributed
# correctly (sourced from gha-workflow-templates/, not .github/workflows/).
#
# Source: https://github.com/amulya-labs/claude-code-config
# License: MIT (https://opensource.org/licenses/MIT)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANAGE_SCRIPT="$REPO_ROOT/scripts/manage-agents.sh"

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

echo "=== Workflow template file locations ==="

EXPECTED_TEMPLATES=(claude.yml claude-code-review.yml)

for f in "${EXPECTED_TEMPLATES[@]}"; do
    if [[ -f "$REPO_ROOT/gha-workflow-templates/$f" ]]; then
        assert "gha-workflow-templates/$f exists" "pass"
    else
        assert "gha-workflow-templates/$f exists" "fail" "File not found"
    fi
done

for f in "${EXPECTED_TEMPLATES[@]}"; do
    if [[ ! -f "$REPO_ROOT/.github/workflows/$f" ]]; then
        assert ".github/workflows/$f does NOT exist (not live)" "pass"
    else
        assert ".github/workflows/$f does NOT exist (not live)" "fail" \
            "File should not be in .github/workflows/ — it would run as a live GitHub Action"
    fi
done

echo

# ── manage-agents.sh script checks ─────────────────────────────────

echo "=== manage-agents.sh flag and function checks ==="

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

# The function should call download_dir with remote=gha-workflow-templates, local=.github/workflows
if grep -q 'download_dir "gha-workflow-templates" ".github/workflows"' "$MANAGE_SCRIPT"; then
    assert "download_gha_workflows maps gha-workflow-templates → .github/workflows" "pass"
else
    assert "download_gha_workflows maps gha-workflow-templates → .github/workflows" "fail" \
        "Expected: download_dir \"gha-workflow-templates\" \".github/workflows\""
fi

echo

# ── shellcheck ──────────────────────────────────────────────────────

echo "=== shellcheck ==="

if command -v shellcheck &>/dev/null; then
    if shellcheck "$MANAGE_SCRIPT" 2>&1; then
        assert "manage-agents.sh passes shellcheck" "pass"
    else
        assert "manage-agents.sh passes shellcheck" "fail"
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
