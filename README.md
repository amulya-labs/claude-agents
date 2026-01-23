# Claude Agents

A collection of reusable Claude Code agents for common software development tasks.

## Installation

Copy the `.claude/agents/` directory to your project:

```bash
cp -r .claude/agents/ /path/to/your/project/.claude/agents/
```

Or copy individual agent files as needed.

## Available Agents

| Agent | Description | Model |
|-------|-------------|-------|
| [code-reviewer](#code-reviewer) | Thorough code reviews for quality and security | opus |
| [debugger](#debugger) | Systematic bug investigation and root cause analysis | opus |
| [documentation-writer](#documentation-writer) | Clear, comprehensive documentation | sonnet |
| [pr-refiner](#pr-refiner) | Refine PRs based on review feedback | sonnet |
| [refactoring-expert](#refactoring-expert) | Improve code structure safely | sonnet |
| [security-auditor](#security-auditor) | Security assessments and vulnerability identification | opus |
| [senior-dev](#senior-dev) | Feature implementation with best practices | opus |
| [systems-architect](#systems-architect) | High-level architecture guidance | opus |
| [test-engineer](#test-engineer) | Comprehensive test suite design | sonnet |

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

Use for architecture questions (not implementation details).

### test-engineer

Designs test suites including:
- Unit, integration, and e2e tests
- Edge case coverage
- Test patterns and anti-patterns
- Quality and maintainability

Use when you need thorough test coverage.

## Usage

Agents are invoked automatically by Claude Code when relevant, or you can reference them explicitly. The agents work best when given clear context about the task at hand.

## Contributing

Feel free to submit PRs to add new agents or improve existing ones. Agents should be:
- Generalized (not project-specific)
- Well-structured with clear sections
- Focused on a specific domain or task

## License

MIT
