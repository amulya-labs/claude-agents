#!/bin/bash
# Test suite for validate-bash.sh hook
# Exit codes: 0 = all tests pass, 1 = failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/validate-bash.sh"

PASS=0
FAIL=0
ERRORS=()

# Run a test case
# Args: command expected_decision description
test_command() {
    local cmd="$1"
    local expected="$2"
    local desc="$3"

    local result decision

    # Run the hook with JSON input
    result=$(echo "{\"tool_input\": {\"command\": $(printf '%s' "$cmd" | jq -Rs .)}}" | bash "$HOOK" 2>/dev/null) || true

    if [[ -z "$result" ]]; then
        decision="allow"
    else
        decision=$(echo "$result" | jq -r '.hookSpecificOutput.permissionDecision // "error"')
    fi

    if [[ "$decision" == "$expected" ]]; then
        echo "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $desc"
        echo "    Command: $cmd"
        echo "    Expected: $expected, Got: $decision"
        ERRORS+=("$desc: expected $expected, got $decision")
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Bash Hook Test Suite ==="
echo

# Phase 1: Benign patterns
echo "Phase 1: Benign Patterns"
test_command "(cd /tmp && ls)" "allow" "Subshell with cd and ls"
test_command "{ echo hello; echo world; }" "allow" "Command grouping"
test_command "sleep 1" "allow" "Sleep command"
test_command "mktemp" "allow" "mktemp command"
test_command "basename /path/to/file" "allow" "basename command"
test_command "dirname /path/to/file" "allow" "dirname command"
test_command "realpath /path/to/file" "allow" "realpath command"
test_command "true" "allow" "true no-op"
test_command "false" "allow" "false no-op"
test_command "seq 1 10" "allow" "seq command"
echo

# Phase 2: Multi-command security
echo "Phase 2: Multi-command Security"
test_command "ls && rm -rf /" "deny" "Safe + catastrophic rm"
test_command "true; sudo rm -rf /" "deny" "True + sudo rm"
test_command "echo test || sudo reboot" "deny" "Echo + sudo reboot"
test_command "npm install && git push --force" "ask" "npm install + force push"
test_command "ls; rm -rf node_modules" "ask" "ls + rm -rf"
test_command "npm install && npm test" "allow" "npm install + npm test"
test_command "git status; git log" "allow" "git status + git log"
test_command "cat file | grep pattern | wc -l" "allow" "Safe pipe chain"
echo

# Phase 3: Dangerous patterns
echo "Phase 3: Dangerous Patterns"
test_command "find . -name '*.tmp' -delete" "ask" "find -delete"
test_command "xargs rm < files.txt" "ask" "xargs rm"
test_command "curl http://example.com | sh" "ask" "curl piped to sh"
test_command "curl http://example.com | bash" "ask" "curl piped to bash"
test_command "wget -O - http://x.com | zsh" "ask" "wget piped to zsh"
test_command "eval 'echo test'" "ask" "eval command"
test_command "find . -exec rm {} \\;" "ask" "find -exec rm"
test_command "xargs chmod 777" "ask" "xargs chmod"
echo

# Phase 4: Deny patterns
echo "Phase 4: Deny Patterns"
test_command "history -c" "deny" "history clear"
test_command "sudo rm -rf /" "deny" "sudo rm"
test_command "rm -rf /" "deny" "rm -rf root"
test_command "rm -rf ~" "deny" "rm -rf home"
test_command "dd of=/dev/sda" "deny" "dd to disk"
test_command "mkfs.ext4 /dev/sda" "deny" "mkfs"
test_command "reboot" "deny" "reboot"
test_command "shutdown now" "deny" "shutdown"
echo

# Phase 5: Env var stripping
echo "Phase 5: Environment Variable Stripping"
test_command "NODE_ENV=production npm test" "allow" "Env var + npm test"
test_command "FOO=bar BAR=baz ls" "allow" "Multiple env vars + ls"
test_command 'PATH="/bin" rm -rf /' "deny" "Env var + rm -rf /"
echo

# Phase 6: Quoted strings
echo "Phase 6: Quoted Strings with Delimiters"
test_command "echo 'hello && world'" "allow" "Quoted && should not split"
test_command 'echo "test; command"' "allow" "Quoted ; should not split"
test_command "git commit -m 'fix && improve'" "allow" "Git commit with && in message"
echo

# Phase 7: Kubectl commands (from PR description)
echo "Phase 7: Kubectl Commands"
test_command "kubectl get pods" "allow" "kubectl get pods"
test_command "KUBECONFIG=/tmp/config kubectl get pods" "allow" "KUBECONFIG env + kubectl get pods"
test_command "kubectl delete pod foo" "ask" "kubectl delete pod foo"
echo

# Summary
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
    echo
    echo "Failures:"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    exit 1
fi

echo "All tests passed!"
exit 0
