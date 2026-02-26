# Claude Code Config

[![CI](https://github.com/amulya-labs/claude-code-config/actions/workflows/ci.yml/badge.svg)](https://github.com/amulya-labs/claude-code-config/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/amulya-labs/claude-code-config/badge)](https://scorecard.dev/viewer/?uri=github.com/amulya-labs/claude-code-config)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-19-blue.svg)](.claude/agents/)

**Production-ready configuration for Claude Code.** Agents, hooks, and settings you can drop into any project.

## Quick Install

```bash
mkdir -p scripts && curl -fsSL -o scripts/manage-claude-code-config.sh https://raw.githubusercontent.com/amulya-labs/claude-code-config/main/scripts/manage-claude-code-config.sh && chmod +x scripts/manage-claude-code-config.sh && ./scripts/manage-claude-code-config.sh install
```

## What You Get

### Planning
| Agent | What it does |
|-------|--------------|
| **tech-lead** | Breaks down work, creates implementation plans, makes technical decisions |
| **systems-architect** | Explains architecture, analyzes change impact, maps data flows |
| **product-owner** | Defines product direction, writes specs, prioritizes ruthlessly |

### Building
| Agent | What it does |
|-------|--------------|
| **senior-dev** | Implements features with production-quality code and tests |
| **debugger** | Investigates bugs systematically with root cause analysis |
| **refactoring-expert** | Improves code structure without changing behavior |
| **prompt-engineer** | Crafts effective prompts for AI models |
| **agent-specialist** | Designs and optimizes AI agents with strong contracts |

### Quality
| Agent | What it does |
|-------|--------------|
| **code-reviewer** | Reviews code for correctness, security, and maintainability |
| **test-engineer** | Designs comprehensive test suites (unit, integration, e2e) |
| **security-auditor** | Identifies vulnerabilities and recommends mitigations |

### Operations
| Agent | What it does |
|-------|--------------|
| **prod-engineer** | Triages incidents, diagnoses with evidence, hardens systems |
| **pr-refiner** | Processes PR feedback and implements changes with critical thinking |
| **documentation-writer** | Creates minimal, DRY documentation |
| **claudemd-architect** | Creates and updates CLAUDE.md files for agent-ready repos |

### Data & ML
| Agent | What it does |
|-------|--------------|
| **ml-architect** | Designs ML systems end-to-end: data pipelines, training, serving, monitoring |

### Sales / Solutions
| Agent | What it does |
|-------|--------------|
| **solution-eng** | Runs discovery, designs solutions, manages POCs |
| **marketing-lead** | Crafts positioning, messaging, and go-to-market copy that converts |

### Creative
| Agent | What it does |
|-------|--------------|
| **digital-designer** | Creates print-ready layouts (booklets, brochures, posters) |

## Usage

Invoke agents with `@agent-name` in Claude Code:

```
@tech-lead plan how to add user notifications
@senior-dev add pagination to the users endpoint
@debugger the API returns 500 on POST /users
@security-auditor review the authentication module
@systems-architect how does caching work in this service?
@code-reviewer check my changes before I open a PR
```

Claude can also select agents automatically based on your request.

## Available Agents

<table>
<tr><th>Agent</th><th>Description</th><th>Model</th></tr>
<tr><td>agent-specialist</td><td>Design and optimize AI agents with strong contracts</td><td rowspan="11">opus</td></tr>
<tr><td>claudemd-architect</td><td>Create and update CLAUDE.md files for agent-ready repos</td></tr>
<tr><td>marketing-lead</td><td>Positioning, messaging, and go-to-market copy</td></tr>
<tr><td>ml-architect</td><td>End-to-end ML system design and production ML decisions</td></tr>
<tr><td>prod-engineer</td><td>Production incident response and reliability engineering</td></tr>
<tr><td>product-owner</td><td>Product direction, prioritization, specs, and decisions</td></tr>
<tr><td>prompt-engineer</td><td>Engineer effective prompts for AI models</td></tr>
<tr><td>security-auditor</td><td>Security assessments and vulnerability identification</td></tr>
<tr><td>solution-eng</td><td>Technical sales, discovery, POCs, and solution design</td></tr>
<tr><td>systems-architect</td><td>High-level architecture guidance</td></tr>
<tr><td>tech-lead</td><td>Plan implementation approaches, break down tasks</td></tr>
<tr><td>code-reviewer</td><td>Thorough code reviews for quality and security</td><td rowspan="8">sonnet</td></tr>
<tr><td>debugger</td><td>Systematic bug investigation and root cause analysis</td></tr>
<tr><td>digital-designer</td><td>Print-ready layouts for booklets, brochures, posters</td></tr>
<tr><td>documentation-writer</td><td>Clear, minimal documentation following DRY principles</td></tr>
<tr><td>pr-refiner</td><td>Refine PRs based on review feedback</td></tr>
<tr><td>refactoring-expert</td><td>Improve code structure safely</td></tr>
<tr><td>senior-dev</td><td>Feature implementation with best practices</td></tr>
<tr><td>test-engineer</td><td>Comprehensive test suite design</td></tr>
<tr><td>junior-dev</td><td>Focused, well-scoped tasks for early-career developers</td><td>haiku</td></tr>
</table>

<details>
<summary>Installation Options</summary>

### Option 1: Curl-based Script (Recommended)

```bash
mkdir -p scripts
curl -fsSL -o scripts/manage-claude-code-config.sh https://raw.githubusercontent.com/amulya-labs/claude-code-config/main/scripts/manage-claude-code-config.sh
chmod +x scripts/manage-claude-code-config.sh
./scripts/manage-claude-code-config.sh install
```

Update later with `./scripts/manage-claude-code-config.sh update`.

### Option 2: Git Subtree

```bash
# Install the manager globally
curl -fsSL -o ~/bin/git-subtree-mgr https://raw.githubusercontent.com/amulya-labs/claude-code-config/main/scripts/git-subtree-mgr
chmod +x ~/bin/git-subtree-mgr

# Add .claude as a subtree
git-subtree-mgr add --prefix=.claude --repo=amulya-labs/claude-code-config --path=.claude
```

Update later with `git-subtree-mgr pull .claude`.

### Option 3: Manual Copy

```bash
git clone https://github.com/amulya-labs/claude-code-config.git
cp -r claude-code-config/.claude/ /path/to/your/project/.claude/
```

</details>

## Hooks

The `.claude/hooks/` directory includes Bash command validation hooks that auto-approve safe commands and block dangerous ones. Patterns are defined in `bash-patterns.toml`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for hook configuration details.

## Scripts

| Script | Purpose |
|--------|---------|
| `manage-claude-code-config.sh` | Install and update `.claude` config and GHA workflows via curl (no git knowledge needed) |
| `git-subtree-mgr` | Manage git subtrees with history tracking (install globally in `~/bin`) |

Run `./scripts/manage-claude-code-config.sh --help` or `git-subtree-mgr --help` for usage.

## Contributing

PRs welcome. Agents should be generalized (no project-specific references), focused (one domain per agent), and well-structured. See [CONTRIBUTING.md](CONTRIBUTING.md) for the agent file format and guidelines.

## License

MIT
