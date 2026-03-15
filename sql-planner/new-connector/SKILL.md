---
name: sql-planner:new-connector
description: >-
  Wizard to generate a sql-planner connector for the current project. Creates a project-level skill with domain knowledge, remote environments, and DB engine config.
version: 1.0.0
---

Wizard that generates a `sql-planner` connector for the current project.

A connector is a project-level skill that provides `sql-planner` with: domain knowledge (table meanings, relationships, business conventions), remote environment connections, and engine configuration.

## Step 1 — Gather Context (parallel)

Run these two tasks in parallel:

### 1a. Infer Domain Knowledge

Launch an Agent (subagent_type: Explore) to analyze the project and infer domain knowledge:

- Read ORM models (Django `models.py`, Rails models, Eloquent models, etc.)
- Read migrations to understand relationships (FKs, many-to-many, indexes)
- Read the DB schema if `.claude/sql-planner/schema.tsv` already exists
- Infer: what tables exist, how they relate, what fields mean, naming conventions, status/enum values

The agent returns a structured summary of domain knowledge.

### 1b. Detect Engine

Infer the DB engine from the project (same approach as sql-planner Step 1a):

- `docker-compose.yml` → mysql/postgres
- Django DATABASES → ENGINE
- Rails database.yml → adapter
- `db.sqlite3` → SQLite
- If unclear → ask the user

## Step 2 — Configure Environments

Use `AskUserQuestion` to ask: "What remote environments do you want to configure?"

- **options**: Common options like `["staging", "production", "staging + production", "None"]`

For each selected environment, ask with `AskUserQuestion`:
- Connection command or method (SSH tunnel, bastion host, direct connection string, etc.)
- Example: `ssh staging-bastion "mysql -h staging-db.internal -u app -pXXX mydb --table -e '{sql}'"`

The `{sql}` placeholder is where `sql-planner` will inject the generated query at runtime.

## Step 3 — Generate Connector

Determine the project name from the current directory name or package config.

Create `.claude/skills/sql-planner-<project>/SKILL.md` with:

```markdown
---
name: sql-planner:<project>
description: Connector for <project> databases
version: 1.0.0
---

## SQL Connector

- Engine: <detected engine>

## Environments

### <environment>
`<connection command with {sql} placeholder>`

## Domain Knowledge

<inferred domain knowledge from Step 1>
```

## Step 4 — Review

Show the generated connector file to the user for review and adjustments. Apply any requested changes before finishing.
