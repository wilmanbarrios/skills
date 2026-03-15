---
name: run-sql
description: Execute SQL on the local development database. Auto-detects connection method from project context.
version: 1.0.0
---

Execute SQL on the local development database. Auto-detects connection method from project context.

## SQL Runner
- **DB Engine**: auto-detect (see Step 1)
- **Schema File**: `.claude/natural-sql/schema.tsv` (if exists)

## Claim Conditions

I claim the query when:
- User explicitly mentions "local", "localhost", "docker", "my db", "dev db"
- User does NOT mention a remote environment (production, staging, etc.)
- No other runner has claimed the query (I am the **default fallback**)
- User mentions project-specific tables without specifying a remote environment — this means local

**Key rule**: If the user says "traeme los usuarios en telespine user" without mentioning prod/stg/dev, I claim it and run it against the local DB. I infer the connection from the project context (Docker, Django settings, etc.).

## Step 1 — Determine Connection Method

**Priority order:**

1. **`.claude/natural-sql/config.md`** exists with `## Query Command` → use it as-is
2. **Auto-detect from project:**
   - `docker-compose.yml` / `compose.yml`:
     - `mysql`/`mariadb` image → `docker compose exec <service> mysql -u <user> -p<pass> <dbname> --table -e "{sql}"`
     - `postgres` image → `docker compose exec <service> psql -U <user> -d <dbname> -c "{sql}"`
   - Django `DATABASES` setting → build CLI command from ENGINE/HOST/NAME/USER/PASSWORD
   - Rails `config/database.yml` → extract dev config
   - `db.sqlite3` exists → `sqlite3 db.sqlite3 "{sql}"`
3. **Can't detect** → ask user, suggest saving to `.claude/natural-sql/config.md`

## Step 2 — Execute

Run the determined command with the SQL.

## Step 3 — Display Results

Format and show the output to the user.

## Safety Rules

- **READ-ONLY by default.** Warn on write operations (`INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, `CREATE`).
- **Never run** `DROP DATABASE` or `TRUNCATE`.
- Escape quotes properly for shell transit.
