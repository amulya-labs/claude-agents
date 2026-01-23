# Claude Agents

[![CI](https://github.com/rrlamichhane/claude-agents/actions/workflows/ci.yml/badge.svg)](https://github.com/rrlamichhane/claude-agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-10-blue.svg)](.claude/agents/)

A collection of reusable Claude Code agents for common software development tasks.

## Installation

### For Git Repos (Recommended)

Use git subtree to add agents to your project. This keeps agents updatable while committing them to your repo.

**First-time setup:**

```bash
# Download the helper script
curl -o scripts/manage-agents.sh https://raw.githubusercontent.com/rrlamichhane/claude-agents/main/scripts/manage-agents.sh
chmod +x scripts/manage-agents.sh

# Install agents
./scripts/manage-agents.sh install
git push
```

**Update agents later:**

```bash
./scripts/manage-agents.sh update
git push
```

**For collaborators:** Just `git clone` and `git pull` as normal - agents are included in the repo.

### Quick Copy (Non-git or One-time Use)

```bash
git clone https://github.com/rrlamichhane/claude-agents.git
cp -r claude-agents/.claude/agents/ /path/to/your/project/.claude/agents/
```

Or copy individual agent files from [`.claude/agents/`](.claude/agents/).

## Available Agents

| Agent | Description | Model |
|-------|-------------|-------|
| [code-reviewer](#code-reviewer) | Thorough code reviews for quality and security | default |
| [debugger](#debugger) | Systematic bug investigation and root cause analysis | opus |
| [documentation-writer](#documentation-writer) | Clear, comprehensive documentation | default |
| [pr-refiner](#pr-refiner) | Refine PRs based on review feedback | default |
| [refactoring-expert](#refactoring-expert) | Improve code structure safely | default |
| [security-auditor](#security-auditor) | Security assessments and vulnerability identification | opus |
| [senior-dev](#senior-dev) | Feature implementation with best practices | default |
| [systems-architect](#systems-architect) | High-level architecture guidance | opus |
| [tech-lead](#tech-lead) | Plan implementation approaches, break down tasks | opus |
| [test-engineer](#test-engineer) | Comprehensive test suite design | default |

## Agent Details

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
| Plan a feature | `@tech-lead plan how to add user notifications` |
| Architecture question | `@systems-architect how does caching work here?` |
| Implement feature | `@senior-dev add pagination to the users endpoint` |
| Debug an issue | `@debugger the API returns 500 on POST` |
| Security review | `@security-auditor review the auth module` |
| Review code | `@code-reviewer check my changes` |
| Write tests | `@test-engineer add tests for the payment service` |
| Refactor code | `@refactoring-expert clean up the legacy handlers` |
| Address PR feedback | `@pr-refiner address the review comments` |
| Write docs | `@documentation-writer create API docs for this module` |

### Learn More

See the [Claude Code agents documentation](https://docs.anthropic.com/en/docs/claude-code/agents) for more details.

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
