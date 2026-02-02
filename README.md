# Claude Agents

[![CI](https://github.com/rrlamichhane/claude-agents/actions/workflows/ci.yml/badge.svg)](https://github.com/rrlamichhane/claude-agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-14-blue.svg)](.claude/agents/)

A collection of reusable Claude Code agents for common software development tasks.

## Installation

### Option 1: Curl-based Script (Simplest)

Use `manage-agents.sh` to download agents directly from GitHub. No git subtree knowledge needed.

```bash
# Download the helper script
mkdir -p scripts
curl -fsSL -o scripts/manage-agents.sh https://raw.githubusercontent.com/rrlamichhane/claude-agents/main/scripts/manage-agents.sh
chmod +x scripts/manage-agents.sh

# Install agents
./scripts/manage-agents.sh install
git commit -m "Add claude-agents"
```

Update later with `./scripts/manage-agents.sh update`.

### Option 2: Git Subtree (Version-tracked)

Use `git-subtree-mgr` for proper git subtree management with history tracking.

```bash
# One-time: install the script globally
curl -fsSL -o ~/bin/git-subtree-mgr https://raw.githubusercontent.com/rrlamichhane/claude-agents/main/scripts/git-subtree-mgr
chmod +x ~/bin/git-subtree-mgr

# Add agents as a subtree
git-subtree-mgr add --prefix=.claude/agents --repo=rrlamichhane/claude-agents --path=.claude/agents
git commit -m "Add claude-agents subtree"
```

Update later with `git-subtree-mgr pull .claude/agents`.

### Option 3: Manual Copy

```bash
git clone https://github.com/rrlamichhane/claude-agents.git
cp -r claude-agents/.claude/agents/ /path/to/your/project/.claude/agents/
```

Or copy individual agent files from [`.claude/agents/`](.claude/agents/).

## Available Agents

| Agent | Description | Model |
|-------|-------------|-------|
| [agent-specialist](#agent-specialist) | Design and optimize AI agents with strong contracts | opus |
| [code-reviewer](#code-reviewer) | Thorough code reviews for quality and security | default |
| [debugger](#debugger) | Systematic bug investigation and root cause analysis | opus |
| [documentation-writer](#documentation-writer) | Clear, comprehensive documentation | default |
| [pr-refiner](#pr-refiner) | Refine PRs based on review feedback | default |
| [prod-engineer](#prod-engineer) | Production incident response and reliability engineering | opus |
| [product-owner](#product-owner) | Product direction, prioritization, specs, and decisions | default |
| [refactoring-expert](#refactoring-expert) | Improve code structure safely | default |
| [security-auditor](#security-auditor) | Security assessments and vulnerability identification | opus |
| [senior-dev](#senior-dev) | Feature implementation with best practices | default |
| [solution-eng](#solution-eng) | Technical sales, discovery, POCs, and solution design | default |
| [systems-architect](#systems-architect) | High-level architecture guidance | opus |
| [tech-lead](#tech-lead) | Plan implementation approaches, break down tasks | opus |
| [test-engineer](#test-engineer) | Comprehensive test suite design | default |

## Agent Details

### agent-specialist

Designs and optimizes AI agents:
- Output contract design (structure, completion criteria, quality bar)
- Guardrail engineering (behavioral constraints, safety gates)
- Knowledge organization (principles, processes, patterns)
- Agent review and improvement

Use when creating new agents or improving existing ones.

### code-reviewer

Performs thorough code reviews focusing on:
- Correctness and logic errors
- Security vulnerabilities
- Performance issues
- Maintainability and best practices

Use when you need a fresh perspective on code quality.

### debugger

Investigates bugs systematically using:
- Root cause analysis
- Hypothesis-driven investigation
- Evidence collection
- Comprehensive fix documentation

Use when troubleshooting errors or unexpected behavior.

### documentation-writer

Creates clear documentation including:
- README files
- API documentation
- Architecture docs
- How-to guides and tutorials

Use when documentation needs to be written or improved.

### pr-refiner

Refines PRs based on review feedback by:
- Extracting all review comments
- Creating prioritized todo lists
- Critically evaluating suggestions
- Implementing changes or pushing back with reasoning

Use when addressing code review comments to refine your PR.

### prod-engineer

Handles production incidents and reliability engineering:
- Triage and stabilize (reduce blast radius, restore service)
- Evidence-driven diagnosis (metrics, logs, traces)
- Safe mitigations with rollback plans
- System hardening (alerts, runbooks, tests)

Use for outages, performance issues, infrastructure problems, and incident response.

### product-owner

Drives product direction and decisions:
- Problem definition and customer validation
- Prioritization (RICE, value vs effort, MoSCoW)
- PRD-lite specs and user stories
- Roadmap and stakeholder communication

Use for feature planning, writing specs, prioritization decisions, and product strategy.

### refactoring-expert

Improves code structure by:
- Identifying code smells
- Applying safe refactoring patterns
- Preserving behavior through testing
- Making incremental improvements

Use for cleaning up technical debt.

### security-auditor

Performs security assessments covering:
- Authentication and authorization
- Input validation (injection attacks)
- Data protection
- API and configuration security

Use for security reviews and threat modeling.

### senior-dev

Implements features with:
- Production-quality code
- Comprehensive testing
- Proper error handling
- CI/CD integration

Use for development tasks requiring best practices.

### solution-eng

Bridges product capabilities and customer needs:
- Discovery (business goals, technical requirements, stakeholders)
- Solution design and architecture
- Demo and POC planning
- Objection handling with technical integrity

Use for technical sales support, customer discovery, and solution validation.

### systems-architect

Provides architectural guidance on:
- System design and component interactions
- Data flows and workflows
- Change impact analysis
- Delegation and project scoping

Use for understanding how systems work and analyzing impact of changes.

### tech-lead

Plans implementation approaches by:
- Breaking down complex tasks into actionable steps
- Creating implementation plans with milestones
- Identifying risks, dependencies, and blockers
- Making high-level technical decisions

Use for scoping work and planning how to build something. Does not write code.

### test-engineer

Designs test suites including:
- Unit, integration, and e2e tests
- Edge case coverage
- Test patterns and anti-patterns
- Quality and maintainability

Use when you need thorough test coverage.

## Usage

### Quick Start

Once installed, agents are available in your Claude Code sessions.

**Automatic invocation** — Claude selects the appropriate agent based on your request:

```
> Review this PR for security issues
# Claude automatically uses security-auditor agent
```

**Explicit invocation** — Use `@agent-name` to invoke a specific agent:

```
> @systems-architect analyze the data flow in this service
> @debugger help me find why this test is failing
> @security-auditor review the authentication module
```

### Examples

| Task | Command |
|------|---------|
| Create an agent | `@agent-specialist design an agent for code migrations` |
| Plan a feature | `@tech-lead plan how to add user notifications` |
| Architecture question | `@systems-architect how does caching work here?` |
| Implement feature | `@senior-dev add pagination to the users endpoint` |
| Customer POC | `@solution-eng plan a POC for Acme Corp's integration needs` |
| Debug an issue | `@debugger the API returns 500 on POST` |
| Production incident | `@prod-engineer latency spiked after the last deploy` |
| Write a PRD | `@product-owner write a spec for user notifications` |
| Security review | `@security-auditor review the auth module` |
| Review code | `@code-reviewer check my changes` |
| Write tests | `@test-engineer add tests for the payment service` |
| Refactor code | `@refactoring-expert clean up the legacy handlers` |
| Address PR feedback | `@pr-refiner address the review comments` |
| Write docs | `@documentation-writer create API docs for this module` |

### Learn More

See the [Claude Code agents documentation](https://docs.anthropic.com/en/docs/claude-code/agents) for more details.

## Scripts

This repo includes two helper scripts for managing agents.

### manage-agents.sh

A simple curl-based script for installing and updating agents from this repo. Designed to be copied into your project.

```bash
./scripts/manage-agents.sh install   # First-time setup
./scripts/manage-agents.sh update    # Pull latest agents
```

**How it works:** Downloads `.md` files directly from GitHub using the API, no git subtree complexity.

### git-subtree-mgr

A generic git subtree manager that works with any repository. Install it globally in `~/bin` and use it across all your projects.

```bash
# Install globally
cp scripts/git-subtree-mgr ~/bin/
chmod +x ~/bin/git-subtree-mgr

# Or download directly
curl -fsSL -o ~/bin/git-subtree-mgr https://raw.githubusercontent.com/rrlamichhane/claude-agents/main/scripts/git-subtree-mgr
chmod +x ~/bin/git-subtree-mgr
```

**Usage:**

```bash
git-subtree-mgr add --prefix=PATH --repo=OWNER/REPO [--branch=BRANCH]
git-subtree-mgr pull [PREFIX]
git-subtree-mgr list
```

**Features:**
- Stores subtree config in `.github/.gitsubtrees`
- Supports GitHub shorthand (`owner/repo`) or full URLs
- Uses `--squash` by default (use `--no-squash` for full history)
- Works from any directory within a git repo

Run `git-subtree-mgr --help` for full options.

<details>
<summary>Which script should I use?</summary>

| Use case | Recommended |
|----------|-------------|
| Just want the agents, minimal setup | `manage-agents.sh` |
| Want git history of upstream changes | `git-subtree-mgr` |
| Managing multiple subtrees in a project | `git-subtree-mgr` |
| Non-technical team members | `manage-agents.sh` |

</details>

## Contributing

PRs welcome! When adding or improving agents:

- **Generalized** — No project-specific references
- **Well-structured** — Use clear sections with headers and bullets
- **Focused** — One domain or task per agent
- **Tested** — Ensure CI passes (validates frontmatter syntax)

### Agent File Format

```yaml
---
name: agent-name
description: Brief description of when to use this agent.
model: opus  # optional: opus, sonnet, haiku (omit for default)
color: blue  # optional: terminal color
---

# Agent Title

Agent instructions in markdown...
```

## License

MIT
