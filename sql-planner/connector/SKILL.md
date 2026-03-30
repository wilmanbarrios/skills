---
name: sql-planner:connector
description: >-
  Wizard to generate a sql-planner connector for the current project. Creates a config file with domain knowledge, remote environments, and DB engine config.
version: 1.1.0
---

Wizard that generates a `sql-planner` connector for the current project.

A connector is a config file at `.claude/sql-planner/config.md` that provides `sql-planner` with: domain knowledge (table meanings, relationships, business conventions), remote environment connections, and engine configuration.

## Step 1 — Gather Context (parallel)

Run these two tasks in parallel:

### 1a. Infer Domain Knowledge

Launch an Agent (subagent_type: Explore) to analyze the project and infer domain knowledge:

- Read ORM models (Django `models.py`, Rails models, Eloquent models, etc.)
- Read migrations to understand relationships (FKs, many-to-many, indexes)
- Read the DB schema if `.claude/sql-planner/schema.tsv` already exists
- Infer: what tables exist, how they relate, what fields mean, naming conventions, status/enum values

The agent returns a structured summary of domain knowledge following this format — one bullet per entity/table, table name in backticks, key fields and their meanings:

```markdown
- **Users**: `users_user` is the main user table. `is_coach=1` means provider. `is_active` controls login access.
- **Sessions**: `signed_in`, `last_activity`, `signed_out` track user login sessions.
- **Subscriptions**: Stripe integration. `credits` tracks usage allowance.
```

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
- Example: `ssh staging-bastion "mysql -h staging-db.internal -u app -p\$DB_PASSWORD mydb --table -e '{sql}'"`

The `{sql}` placeholder is where `sql-planner` will inject the generated query at runtime.

## Step 3 — Generate Connector

Create `.claude/sql-planner/config.md` with:

```markdown
## Engine
<detected engine>

## Environments

### <environment>
`<connection command with {sql} placeholder>`

## Domain Knowledge

<inferred domain knowledge from Step 1>
```

## Step 4 — Validate

Test the connector by running the schema generation query (from sql-planner Step 1d) against the local environment. If it returns results, the connector is working. If it fails, diagnose and fix the connection command before proceeding.

## Step 5 — Review

Show the generated connector file to the user for review and adjustments. Apply any requested changes before finishing.
