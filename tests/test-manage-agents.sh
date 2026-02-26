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

if grep -q 'download_gha_workflow_templates()' "$MANAGE_SCRIPT"; then
    assert "Function download_gha_workflow_templates() exists" "pass"
else
    assert "Function download_gha_workflow_templates() exists" "fail"
fi

if ! grep -q 'download_workflows()' "$MANAGE_SCRIPT"; then
    assert "Old function download_workflows() is removed" "pass"
else
    assert "Old function download_workflows() is removed" "fail" \
        "Found stale download_workflows() definition"
fi

echo

# ── download_gha_workflows explicit file downloads ──────────────────

echo "=== download_gha_workflows explicit file downloads ==="

# The function should explicitly download only the two Claude workflow files,
# not use download_dir (which would fetch all files in the directory including ci.yml etc.)
if grep -q 'for wf in claude.yml claude-code-review.yml' "$MANAGE_SCRIPT"; then
    assert "download_gha_workflows fetches only claude.yml and claude-code-review.yml" "pass"
else
    assert "download_gha_workflows fetches only claude.yml and claude-code-review.yml" "fail" \
        "Expected: for wf in claude.yml claude-code-review.yml"
fi

if ! grep -q 'download_dir ".github/workflows" ".github/workflows"' "$MANAGE_SCRIPT"; then
    assert "download_gha_workflows does not use download_dir (avoids fetching ci.yml etc.)" "pass"
else
    assert "download_gha_workflows does not use download_dir (avoids fetching ci.yml etc.)" "fail" \
        "Should not use download_dir for workflows — it would fetch all files in the directory"
fi

echo

# ── download_all() behavior checks ───────────────────────────────────

echo "=== download_all() behavior ==="

# download_gha_workflows should be called unconditionally (not inside an if $WITH_GHA_WORKFLOWS block)
# Extract the download_all() body and verify the call appears outside any conditional block
download_all_body=$(sed -n '/^download_all()/,/^}/p' "$MANAGE_SCRIPT")
conditional_block=$(echo "$download_all_body" | sed -n '/if \$WITH_GHA_WORKFLOWS/,/fi/p')
if echo "$download_all_body" | grep -q 'download_gha_workflows$' && \
   ! echo "$conditional_block" | grep -q 'download_gha_workflows$'; then
    assert "download_gha_workflows is called unconditionally in download_all()" "pass"
else
    assert "download_gha_workflows is called unconditionally in download_all()" "fail" \
        "download_gha_workflows should not be inside an if \$WITH_GHA_WORKFLOWS block"
fi

# download_gha_workflow_templates should be called conditionally
if grep -B1 'download_gha_workflow_templates' "$MANAGE_SCRIPT" | grep -q 'if \$WITH_GHA_WORKFLOWS'; then
    assert "download_gha_workflow_templates is called conditionally with WITH_GHA_WORKFLOWS" "pass"
else
    assert "download_gha_workflow_templates is called conditionally with WITH_GHA_WORKFLOWS" "fail" \
        "download_gha_workflow_templates should be inside an if \$WITH_GHA_WORKFLOWS block"
fi

if grep -q 'github-workflow-templates' "$MANAGE_SCRIPT"; then
    assert "Script references github-workflow-templates directory" "pass"
else
    assert "Script references github-workflow-templates directory" "fail" \
        "Expected reference to github-workflow-templates in script"
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
