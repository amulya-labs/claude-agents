# Claude Code Config

[![CI](https://github.com/amulya-labs/claude-code-config/actions/workflows/ci.yml/badge.svg)](https://github.com/amulya-labs/claude-code-config/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/amulya-labs/claude-code-config/badge)](https://scorecard.dev/viewer/?uri=github.com/amulya-labs/claude-code-config)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-17-blue.svg)](.claude/agents/)

**Production-ready configuration for Claude Code.** Agents, hooks, and settings you can drop into any project.

## Quick Install

```bash
mkdir -p scripts && curl -fsSL -o scripts/manage-agents.sh https://raw.githubusercontent.com/amulya-labs/claude-code-config/main/scripts/manage-agents.sh && chmod +x scripts/manage-agents.sh && ./scripts/manage-agents.sh install
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

### Sales / Solutions
| Agent | What it does |
|-------|--------------|
| **solution-eng** | Runs discovery, designs solutions, manages POCs |

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

| Agent | Description | Model |
|-------|-------------|-------|
| agent-specialist | Design and optimize AI agents with strong contracts | opus |
| claudemd-architect | Create and update CLAUDE.md files for agent-ready repos | opus |
| code-reviewer | Thorough code reviews for quality and security | default |
| debugger | Systematic bug investigation and root cause analysis | opus |
| digital-designer | Print-ready layouts for booklets, brochures, posters | opus |
| documentation-writer | Clear, minimal documentation following DRY principles | default |
| pr-refiner | Refine PRs based on review feedback | default |
| prod-engineer | Production incident response and reliability engineering | opus |
| product-owner | Product direction, prioritization, specs, and decisions | default |
| prompt-engineer | Engineer effective prompts for AI models | opus |
| refactoring-expert | Improve code structure safely | default |
| security-auditor | Security assessments and vulnerability identification | opus |
| senior-dev | Feature implementation with best practices | default |
| solution-eng | Technical sales, discovery, POCs, and solution design | default |
| systems-architect | High-level architecture guidance | opus |
| tech-lead | Plan implementation approaches, break down tasks | opus |
| test-engineer | Comprehensive test suite design | default |

<details>
<summary>Installation Options</summary>

### Option 1: Curl-based Script (Recommended)

```bash
mkdir -p scripts
curl -fsSL -o scripts/manage-agents.sh https://raw.githubusercontent.com/amulya-labs/claude-code-config/main/scripts/manage-agents.sh
chmod +x scripts/manage-agents.sh
./scripts/manage-agents.sh install
```

Update later with `./scripts/manage-agents.sh update`.

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
| `manage-agents.sh` | Install and update `.claude` config via curl (no git knowledge needed) |
| `git-subtree-mgr` | Manage git subtrees with history tracking (install globally in `~/bin`) |

Run `./scripts/manage-agents.sh --help` or `git-subtree-mgr --help` for usage.

## Contributing

PRs welcome. Agents should be generalized (no project-specific references), focused (one domain per agent), and well-structured. See [CONTRIBUTING.md](CONTRIBUTING.md) for the agent file format and guidelines.

## License

MIT
