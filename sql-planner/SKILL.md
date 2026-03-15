---
name: sql-planner
description: >-
  Generate SQL from natural language. Discovers available runners, reads their schema/domain knowledge, generates the query, and delegates execution.
  TRIGGER when: user asks a data question in natural language (count, list, show, verify, check, how many, cuantos, traeme, muéstrame), mentions database tables, or asks about data in any environment (production, staging, dev, local).
  DO NOT TRIGGER when: user provides raw SQL ready to execute.
version: 1.0.0
---

Generate SQL from natural language. Discovers available runners, reads their schema/domain knowledge, generates the query, and delegates execution.

## Claim Conditions

This skill is the **universal entry point** for any data question expressed in natural language. It MUST be invoked BEFORE any specific runner (`run-sql`, `telespine:run-sql`, etc.).

**I claim when:**
- User asks a question about data in natural language (English or Spanish)
- User wants to "check", "count", "list", "show", "verify", "find" data
- User mentions a database table or business entity (users, subscriptions, sessions, etc.)
- User asks about data in ANY environment (production, staging, dev, local)

**I do NOT claim when:**
- User provides a complete SQL query ready to execute
- User explicitly invokes a specific runner (e.g., `/run-sql SELECT ...`)

## Input

$ARGUMENTS = natural language describing what data the user wants.

## Step 1 — Discover Runners

Scan for runner skills that contain a `## SQL Runner` section:

1. Check `.claude/skills/**/SKILL.md` in the current project directory
2. Check `~/.claude/skills/**/SKILL.md` (user-level runners like `run-sql`)
3. Collect all discovered runners

Use Glob to find SKILL.md files, then Grep or Read to check for the `## SQL Runner` marker.

## Step 2 — Runner Selection (Task Queue)

Read each runner's `## Claim Conditions` section. Evaluate each against the user's original prompt and current project context.

- If exactly one runner claims → proceed with that runner
- If multiple runners claim → ask the user which one to use
- If none claim → inform the user no runner matches this context

## Step 3 — Load Context from Claiming Runner

From the claiming runner's SKILL.md, read:

- `## SQL Runner` → DB engine
- `## Domain Knowledge` → table explanations, business concepts (if present)
- Schema file at the path specified in `## SQL Runner`

Also check for `.claude/natural-sql/schema.tsv` as a generic local schema fallback.

## Step 4 — Generate SQL

- Translate the natural language request into valid SQL using the loaded schema + domain knowledge
- Use the correct dialect for the runner's DB engine (MySQL / PostgreSQL / SQLite)
- Add `LIMIT 25` by default unless the user explicitly wants all rows
- Use readable column aliases for cryptic column names

## Step 5 — Show SQL for Confirmation

Display the generated SQL to the user. Wait for them to confirm before proceeding.

## Step 6 — Delegate to Claiming Runner

Load the claiming runner's skill (via the Skill tool) and pass the SQL plus any context the runner needs (e.g., target environment extracted from the user's prompt).

## Safety Rules

- **READ-ONLY by default.**
- If the SQL contains `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, or `CREATE` → warn the user and require explicit confirmation.
- **Never generate** `DROP DATABASE` or `TRUNCATE`.
- Always show the SQL before delegating. Never execute blindly.

## Schema Maintenance

If a table or column referenced in the prompt is not found in the schema, suggest regenerating. Provide engine-appropriate commands:

**MySQL:**
```sql
SELECT TABLE_NAME, GROUP_CONCAT(CONCAT(COLUMN_NAME, ' ', COLUMN_TYPE, IF(COLUMN_KEY='PRI',' PK',''), IF(COLUMN_KEY='MUL',' FK',''), IF(COLUMN_KEY='UNI',' UQ','')) ORDER BY ORDINAL_POSITION SEPARATOR ', ') FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '<dbname>' GROUP BY TABLE_NAME ORDER BY TABLE_NAME;
```

**PostgreSQL:**
```sql
SELECT table_name, string_agg(column_name || ' ' || data_type, ', ' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = 'public' GROUP BY table_name ORDER BY table_name;
```
