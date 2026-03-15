# AI Coding Agent Skills

Personal collection of reusable skills for AI coding agents. Compatible with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Opencode](https://opencode.ai/).

Skills use the **SKILL.md** format with YAML frontmatter, making them portable across compatible tools.

## Skills Catalog

| Skill | Description |
|-------|-------------|
| [`sql-planner`](./sql-planner/SKILL.md) | Natural language → SQL → execute. Auto-detects local DB, discovers connectors for remote environments |
| [`sql-planner:new-connector`](./sql-planner/new-connector/SKILL.md) | Wizard to generate a project connector with domain knowledge and remote environments |

## Skill Details

### sql-planner

Translates natural language into SQL and executes it against the database. Installed at user level (`~/.claude/skills/`).

**How it works:**

1. **Detects connection** — auto-detects the local DB from project files (docker-compose, Django, Rails, SQLite)
2. **Discovers connectors** — scans for project-level skills with a `## SQL Connector` section
3. **Loads schema** — caches schema in `.claude/sql-planner/schema.tsv`, auto-regenerates when stale
4. **Generates SQL** — produces a query in the correct dialect using schema + domain knowledge from connector
5. **Confirms & executes** — read-only queries run directly on local; write operations always require confirmation
6. **Displays results** — formats and shows the output

**Safety:** read-only by default, warns on write operations, never generates `DROP DATABASE` or `TRUNCATE`.

### Connectors

Connectors are project-level skills that extend `sql-planner` with:

- **Domain knowledge** — table meanings, relationships, business conventions
- **Remote environments** — connection commands for staging, production, etc.
- **Engine config** — explicit DB engine when auto-detection isn't enough

Connectors live in `.claude/skills/sql-planner-<project>/SKILL.md` and are discovered automatically by `sql-planner`.

**Create a connector:**

```bash
# Use the built-in wizard
/sql-planner:new-connector
```

**Connector example:**

```markdown
---
name: sql-planner:myproject
description: Connector for myproject databases
version: 1.0.0
---

## SQL Connector

- Engine: MySQL

## Environments

### staging
`ssh staging-bastion "mysql -h staging-db.internal -u app -pXXX mydb --table -e '{sql}'"`

### production
`ssh prod-bastion "mysql -h prod-db.internal -u readonly -pXXX mydb --table -e '{sql}'"`

## Domain Knowledge

- `users`: stores user accounts (email, name, status)
- `orders`: purchase orders linked to users via user_id
- `status = 1` means active, `status = 0` means inactive
- When counting "users without orders", use LEFT JOIN orders + WHERE NULL
```

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
