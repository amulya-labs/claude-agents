"""
Data-driven parametrized tests for the Bash command validator.

Loads test cases from bash-test-cases.toml and tests the validator
directly (no shell wrapper overhead).

Source: https://github.com/amulya-labs/claude-agents
License: MIT (https://opensource.org/licenses/MIT)
"""

import importlib.util
import sys
from pathlib import Path

import pytest

# Import validate-bash.py (hyphenated filename requires importlib)
HOOKS_DIR = Path(__file__).parent.parent / ".claude" / "hooks"
_spec = importlib.util.spec_from_file_location(
    "validate_bash", HOOKS_DIR / "validate-bash.py"
)
validate_bash = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(validate_bash)

# Python 3.11+ has tomllib built-in
try:
    import tomllib
except ImportError:
    import tomli as tomllib  # type: ignore[no-redef]

# ── Fixtures ──────────────────────────────────────────────────────────────────

TOML_PATH = Path(__file__).parent / "bash-test-cases.toml"
CONFIG_PATH = HOOKS_DIR / "bash-patterns.toml"


@pytest.fixture(scope="session")
def config():
    """Load the TOML pattern configuration once per session."""
    with open(CONFIG_PATH, "rb") as f:
        return tomllib.load(f)


@pytest.fixture(scope="session")
def compiled_patterns(config):
    """Compile all patterns once per session."""
    return {
        "deny": validate_bash.compile_patterns(config, "deny"),
        "ask": validate_bash.compile_patterns(config, "ask"),
        "allow": validate_bash.compile_patterns(config, "allow"),
    }


def load_test_cases():
    """Load test cases from TOML file."""
    with open(TOML_PATH, "rb") as f:
        data = tomllib.load(f)
    return data


# ── Parametrized test data ────────────────────────────────────────────────────

_test_data = load_test_cases()


def _make_ids(category):
    """Generate descriptive test IDs from test case descriptions."""
    return [case["description"] for case in _test_data.get(category, [])]


ALLOW_CASES = [
    (case["command"], case["description"])
    for case in _test_data.get("allow", [])
]

ASK_CASES = [
    (case["command"], case["description"])
    for case in _test_data.get("ask", [])
]

DENY_CASES = [
    (case["command"], case["description"])
    for case in _test_data.get("deny", [])
]


# ── Parametrized tests (data-driven from TOML) ───────────────────────────────


class TestAllowPatterns:
    """Commands that should be auto-approved."""

    @pytest.mark.parametrize(
        "command,description",
        ALLOW_CASES,
        ids=_make_ids("allow"),
    )
    def test_allow(self, compiled_patterns, command, description):
        decision, reason = validate_bash.validate_command(
            command,
            compiled_patterns["deny"],
            compiled_patterns["ask"],
            compiled_patterns["allow"],
        )
        assert decision == "allow", (
            f"Expected allow for '{description}'\n"
            f"  Command: {command}\n"
            f"  Got: {decision} ({reason})"
        )


class TestAskPatterns:
    """Commands that should prompt for confirmation."""

    @pytest.mark.parametrize(
        "command,description",
        ASK_CASES,
        ids=_make_ids("ask"),
    )
    def test_ask(self, compiled_patterns, command, description):
        decision, reason = validate_bash.validate_command(
            command,
            compiled_patterns["deny"],
            compiled_patterns["ask"],
            compiled_patterns["allow"],
        )
        assert decision == "ask", (
            f"Expected ask for '{description}'\n"
            f"  Command: {command}\n"
            f"  Got: {decision} ({reason})"
        )


class TestDenyPatterns:
    """Commands that should always be blocked."""

    @pytest.mark.parametrize(
        "command,description",
        DENY_CASES,
        ids=_make_ids("deny"),
    )
    def test_deny(self, compiled_patterns, command, description):
        decision, reason = validate_bash.validate_command(
            command,
            compiled_patterns["deny"],
            compiled_patterns["ask"],
            compiled_patterns["allow"],
        )
        assert decision == "deny", (
            f"Expected deny for '{description}'\n"
            f"  Command: {command}\n"
            f"  Got: {decision} ({reason})"
        )


# ── Unit tests for internal functions ─────────────────────────────────────────


class TestStripLineContinations:
    """Test backslash-newline line continuation stripping."""

    @pytest.mark.parametrize(
        "input_cmd,expected",
        [
            ("echo test", "echo test"),
            ("echo test && \\\nkubectl get pods", "echo test &&  kubectl get pods"),
            ("\\\nkubectl get pods", " kubectl get pods"),
            ("no continuations here", "no continuations here"),
            ("multi\\\nline\\\ncmd", "multi line cmd"),
        ],
        ids=[
            "no-continuation",
            "after-ampersand",
            "leading-continuation",
            "plain-text",
            "multiple-continuations",
        ],
    )
    def test_strip(self, input_cmd, expected):
        assert validate_bash.strip_line_continuations(input_cmd) == expected


class TestSplitCommands:
    """Test command splitting on &&, ||, ;."""

    @pytest.mark.parametrize(
        "input_cmd,expected_count",
        [
            ("echo hello", 1),
            ("echo a && echo b", 2),
            ("echo a || echo b", 2),
            ("echo a; echo b", 2),
            ("echo a && echo b || echo c", 3),
            ("echo 'a && b'", 1),  # Quoted && not split
            ('echo "a; b"', 1),  # Quoted ; not split
            ("case $x in a);; b);; esac", 1),  # ;; not split
        ],
        ids=[
            "single",
            "and-chain",
            "or-chain",
            "semicolon",
            "triple-chain",
            "quoted-ampersand",
            "quoted-semicolon",
            "case-statement",
        ],
    )
    def test_split_count(self, input_cmd, expected_count):
        assert len(validate_bash.split_commands(input_cmd)) == expected_count


class TestStripEnvVars:
    """Test environment variable prefix stripping."""

    @pytest.mark.parametrize(
        "input_cmd,expected",
        [
            ("ls", "ls"),
            ("FOO=bar ls", "ls"),
            ("FOO=bar BAR=baz ls", "ls"),
            ('FOO="bar baz" ls', "ls"),
            ("FOO='bar baz' ls", "ls"),
            ("NODE_ENV=production npm test", "npm test"),
        ],
        ids=[
            "no-vars",
            "single-var",
            "multiple-vars",
            "double-quoted-var",
            "single-quoted-var",
            "real-world-node-env",
        ],
    )
    def test_strip(self, input_cmd, expected):
        assert validate_bash.strip_env_vars(input_cmd) == expected


class TestCleanSegment:
    """Test full segment cleaning pipeline."""

    @pytest.mark.parametrize(
        "input_seg,expected",
        [
            ("  echo hello  ", "echo hello"),
            ("(echo hello)", "echo hello"),
            ("{echo hello}", "echo hello"),
            ("FOO=bar echo hello", "echo hello"),
            ("\\\nkubectl get pods", "kubectl get pods"),
            ("then echo hello", "echo hello"),
            ("do ls -la", "ls -la"),
            ("done", ""),
            ("fi", ""),
            ("done < input.txt", ""),
        ],
        ids=[
            "whitespace",
            "parens",
            "braces",
            "env-var",
            "line-continuation",
            "then-keyword",
            "do-keyword",
            "done-terminator",
            "fi-terminator",
            "done-with-redirect",
        ],
    )
    def test_clean(self, input_seg, expected):
        assert validate_bash.clean_segment(input_seg) == expected


class TestStripControlFlowKeyword:
    """Test control flow keyword stripping."""

    @pytest.mark.parametrize(
        "input_seg,expected",
        [
            ("then echo hello", "echo hello"),
            ("else echo fallback", "echo fallback"),
            ("do ls -la", "ls -la"),
            ("elif [ -f x ]", "[ -f x ]"),
            ("done", ""),
            ("fi", ""),
            ("esac", ""),
            ("done < file.txt", ""),
            ("fi >> log.txt", ""),
            ("echo hello", "echo hello"),  # Not a keyword
            ("thermal sensor", "thermal sensor"),  # "then" substring
        ],
        ids=[
            "then",
            "else",
            "do",
            "elif",
            "done",
            "fi",
            "esac",
            "done-redirect",
            "fi-redirect",
            "not-keyword",
            "then-substring",
        ],
    )
    def test_strip(self, input_seg, expected):
        assert validate_bash.strip_control_flow_keyword(input_seg) == expected


# ── Edge case integration tests ───────────────────────────────────────────────


class TestEdgeCases:
    """Integration tests for tricky edge cases."""

    @pytest.mark.parametrize(
        "command,expected_decision",
        [
            ("export FOO=bar", "allow"),
            ("ps aux | grep nginx | awk '{print $2}'", "allow"),
            ("", "allow"),  # Empty command
            ("   ", "allow"),  # Whitespace only
        ],
        ids=[
            "export-statement",
            "complex-safe-pipeline",
            "empty-command",
            "whitespace-only",
        ],
    )
    def test_edge_case(self, compiled_patterns, command, expected_decision):
        decision, _ = validate_bash.validate_command(
            command,
            compiled_patterns["deny"],
            compiled_patterns["ask"],
            compiled_patterns["allow"],
        )
        assert decision == expected_decision
