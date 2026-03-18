# AI Coding Agent Skills

Personal collection of reusable skills for AI coding agents. Compatible with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Opencode](https://opencode.ai/).

Skills use the **SKILL.md** format with YAML frontmatter, making them portable across compatible tools.

## Skills

| Skill | Description |
|-------|-------------|
| [`git:commit`](./git/commit/SKILL.md) | Create well-formatted git commits following consistent conventions |
| [`git:branch`](./git/branch/SKILL.md) | Create well-named git branches with consistent type/description/target conventions |
| [`sql-planner`](./sql-planner/SKILL.md) | Natural language → SQL → execute. Auto-detects local DB, discovers connectors for remote environments |
| [`sql-planner:new-connector`](./sql-planner/new-connector/SKILL.md) | Wizard to generate a project connector with domain knowledge and remote environments |
| [`worklog`](./worklog/SKILL.md) | Review and organize daily work logs. Auto-installs a hook that captures prompts from `~/Code/work/` projects |

## Installation

### Using the skills CLI (recommended)

Install individual skills with [`npx skills`](https://www.npmjs.com/package/skills):

```bash
# Install sql-planner globally (user-level, ~/.claude/skills/)
npx skills add wilmanbarrios/skills/sql-planner -g

# Install at project level (.claude/skills/)
npx skills add wilmanbarrios/skills/sql-planner

# Install all skills at once
npx skills add wilmanbarrios/skills --all -g

# List available skills without installing
npx skills add wilmanbarrios/skills -l
```

### Manual

Clone and copy individual skill folders to `~/.claude/skills/`:

```bash
git clone https://github.com/wilmanbarrios/skills.git
cp -r skills/sql-planner ~/.claude/skills/
```

### Opencode

Copy skills to `~/.config/opencode/skills/` (user-level) or `.opencode/skills/` (project-level):

```bash
git clone https://github.com/wilmanbarrios/skills.git
cp -r skills/sql-planner ~/.config/opencode/skills/
```

## Adding New Skills

1. Create a new directory: `your-skill-name/`
2. Add a `SKILL.md` with YAML frontmatter:

```markdown
---
name: your-skill-name
description: What the skill does in one line.
version: 1.0.0
---

Detailed instructions for the AI agent...
```

3. Open a PR against `main`.
