# AI Coding Agent Skills

Personal collection of reusable skills for AI coding agents. Compatible with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Opencode](https://opencode.ai/).

Skills use the **SKILL.md** format with YAML frontmatter, making them portable across compatible tools.

## Skills Catalog

| Skill | Description |
|-------|-------------|
| [`sql-planner`](./sql-planner/SKILL.md) | Generate SQL from natural language — discovers runners, loads schema, and delegates execution |
| [`run-sql`](./run-sql/SKILL.md) | Execute SQL on the local dev database — auto-detects connection method from project context |

## Skill Details

### sql-planner

Translates natural language into SQL queries. It works as an orchestrator:

1. **Discovers runners** — scans for skills that expose a `## SQL Runner` section (project-level and user-level)
2. **Selects a runner** — evaluates each runner's claim conditions against the user's request
3. **Loads context** — reads the runner's DB engine, domain knowledge, and schema
4. **Generates SQL** — produces a query in the correct dialect (MySQL / PostgreSQL / SQLite), with `LIMIT 25` by default
5. **Confirms with the user** — displays the SQL before execution
6. **Delegates execution** — hands off to the claiming runner skill

Safety: read-only by default, warns on write operations, never generates `DROP DATABASE` or `TRUNCATE`.

### run-sql

Executes SQL on the local development database. Acts as a **runner** for `sql-planner` and can also be used standalone.

Connection detection priority:
1. `.claude/natural-sql/config.md` with a `## Query Command` section
2. Auto-detect from project files (`docker-compose.yml`, Django settings, Rails database config, SQLite)
3. Falls back to asking the user

Claims queries when the user mentions local/dev context, or when no other runner matches (default fallback).

## Installation

### Claude Code (Marketplace)

Add the following to your `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "skills": {
      "source": {
        "source": "github",
        "repo": "wilmanbarrios/skills"
      }
    }
  }
}
```

### Opencode

Copy skills to `~/.config/opencode/skills/` (user-level) or `.opencode/skills/` (project-level):

```bash
git clone https://github.com/wilmanbarrios/skills.git
cp -r skills/sql-planner ~/.config/opencode/skills/
cp -r skills/run-sql ~/.config/opencode/skills/
```

### Manual

Copy individual skill folders to `~/.claude/skills/`:

```bash
git clone https://github.com/wilmanbarrios/skills.git
cp -r skills/sql-planner ~/.claude/skills/
cp -r skills/run-sql ~/.claude/skills/
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
