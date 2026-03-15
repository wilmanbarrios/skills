---
name: sql-planner
description: >-
  Natural language → SQL → execute against the database. Auto-detects local connection, discovers project connectors for remote environments and domain knowledge.
  TRIGGER when: user asks a data question in natural language (count, list, show, verify, check, how many, cuantos, traeme, muéstrame), mentions database tables, or asks about data in any environment (production, staging, dev, local).
  DO NOT TRIGGER when: user provides raw SQL ready to execute.
version: 2.0.0
---

Natural language → SQL → execute against the database. Auto-detects local connection, discovers project connectors for remote environments and domain knowledge.

## Claim Conditions

This skill is the entry point for any data question expressed in natural language.

**I claim when:**
- User asks a question about data in natural language (English or Spanish)
- User wants to "check", "count", "list", "show", "verify", "find" data
- User mentions a database table or business entity (users, subscriptions, sessions, etc.)
- User asks about data in ANY environment (production, staging, dev, local)

**I do NOT claim when:**
- User provides a complete SQL query ready to execute
- User asks to create a connector (use `/sql-planner:new-connector` instead)

## Input

$ARGUMENTS = natural language describing what data the user wants.

## Step 1 — Gather Context (parallelized)

Run these 3 tasks in parallel:

### 1a. Detect DB Connection & Engine

Auto-detect the local database connection from the project:

1. **`docker-compose.yml` / `compose.yml`**:
   - `mysql`/`mariadb` image → `docker compose exec <service> mysql -u <user> -p<pass> <dbname> --table -e "{sql}"`
   - `postgres` image → `docker compose exec <service> psql -U <user> -d <dbname> -c "{sql}"`
2. **Django `DATABASES` setting** → build CLI command from ENGINE/HOST/NAME/USER/PASSWORD
3. **Rails `config/database.yml`** → extract dev config
4. **`db.sqlite3` exists** → `sqlite3 db.sqlite3 "{sql}"`
5. **Can't detect** → ask the user

From the detected engine, infer the SQL dialect (MySQL, PostgreSQL, SQLite).

### 1b. Discover Connector

Search for project-level connectors:

1. Glob for `.claude/skills/**/SKILL.md` in the current project directory
2. Grep or Read each result looking for a `## SQL Connector` section
3. If found → read: engine, environments, domain knowledge
4. If the user asks for a remote environment and NO connector exists → inform them and suggest: `/sql-planner:new-connector`

### 1c. Load & Validate Schema

1. If `.claude/sql-planner/schema.tsv` exists:
   - The first line contains metadata: `# count:<N>` (number of total columns)
   - Execute a quick count against the DB and compare with N
   - If differs → regenerate; if matches → use cache
2. If NOT exists → generate automatically from INFORMATION_SCHEMA / `.schema` and save with metadata count

**Schema generation commands:**

**MySQL:**
```sql
SELECT TABLE_NAME, GROUP_CONCAT(CONCAT(COLUMN_NAME, ' ', COLUMN_TYPE, IF(COLUMN_KEY='PRI',' PK',''), IF(COLUMN_KEY='MUL',' FK',''), IF(COLUMN_KEY='UNI',' UQ','')) ORDER BY ORDINAL_POSITION SEPARATOR ', ') FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() GROUP BY TABLE_NAME ORDER BY TABLE_NAME;
```

**PostgreSQL:**
```sql
SELECT table_name, string_agg(column_name || ' ' || data_type, ', ' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 'public' GROUP BY table_name ORDER BY table_name;
```

**SQLite:**
```
.schema
```

**Autonomy principle**: resolve everything possible without asking. But if something is genuinely ambiguous or cannot be inferred with certainty, ask the user — it's better to confirm than to assume wrong.

## Step 2 — Generate SQL

- Translate natural language → SQL using schema + domain knowledge from connector (if exists) + correct dialect
- `LIMIT 25` by default unless the user explicitly asks for all rows
- Use readable column aliases for cryptic column names

## Step 3 — Confirm & Execute

Apply these rules based on the query type and target environment:

- **READ-ONLY + local** → execute directly, no confirmation needed
- **READ-ONLY + remote** → use `AskUserQuestion` to confirm the target environment before executing
- **Write operation (INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, CREATE) in ANY environment** → **ALWAYS** require approval via `AskUserQuestion`. No exceptions.
  - **question**: "⚠️ This query modifies data. Execute?"
  - **preview**: the generated SQL
  - **options**: `["Ejecutar", "Editar", "Cancelar"]`
  - Editar / Other → adjust query, return to Step 3
  - Cancelar → stop

When executing against a remote environment, use the connection command from the connector's `## Environments` section, replacing `{sql}` with the generated query.

## Step 4 — Display Results

Format and show the output to the user.

## Safety Rules

- **READ-ONLY by default.**
- Warn on write operations (`INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, `CREATE`)
- **Never generate** `DROP DATABASE` or `TRUNCATE`
- Always show the SQL before executing
- Remote environments: additional warning before executing

## Schema Maintenance

- If a table or column referenced in the prompt is not found in the schema → regenerate automatically
- After regeneration, save the updated schema to `.claude/sql-planner/schema.tsv` with the new `# count:<N>` metadata line
