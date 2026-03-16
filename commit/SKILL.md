---
name: commit
description: >-
  Create well-formatted git commits following consistent conventions.
  Extracts ticket ID from branch, uses imperative mood, lowercase after prefix.
  TRIGGER when: user invokes /commit or asks to commit staged changes.
  DO NOT TRIGGER when: user wants to push, create a PR, or amend a commit.
version: 1.0.0
disable-model-invocation: true
---

## Input

$ARGUMENTS = optional hint, scope description, or full message override.

## Step 1 — Gather Context

Run all of these in parallel:

### 1a. Staged Changes

```bash
git diff --cached --stat
git diff --cached
```

If nothing is staged, check `git status`. If there are unstaged changes, ask the user what to stage. If the working tree is clean, inform the user there's nothing to commit and stop.

### 1b. Recent Commits

```bash
git log --oneline -10
```

Use this as style reference to stay consistent with the repo's history.

### 1c. Branch & Ticket ID

```bash
git branch --show-current
```

Extract the ticket ID using this pattern: **one or more uppercase letters, a hyphen, one or more digits** (e.g., `OTH-478`, `FEAT-12`, `BUG-3`). The ticket is usually right after the branch type prefix (`feature/`, `fix/`, `hotfix/`, etc.).

- If found → the commit subject will be prefixed with `TICKET-ID: `
- If not found → no prefix; capitalize the first letter of the subject instead

## Step 2 — Draft Commit Message

Compose the commit message following these rules strictly:

### Subject line

| Rule | Example |
|---|---|
| Ticket prefix (if found) + colon + space | `OTH-478: ` |
| **Lowercase** after colon (when ticket prefix exists) | `OTH-478: add CDK infrastructure` |
| **Capitalize** first letter (when NO ticket prefix) | `Remove unneeded command` |
| Imperative mood | "add", "remove", "fix", "update", "protect", "migrate" |
| Specific and descriptive — this is the most important part | NOT "update files" → "add CDK infrastructure and decouple secrets from Telespine" |
| Wrap code references in backticks | "remove `tele_` prefix from settings" |
| No trailing period | `OTH-478: add new endpoint` NOT `OTH-478: add new endpoint.` |
| English only | Always |

### Body (optional)

- **Include** for complex changes: multi-file, significant logic, non-obvious reasoning
- **Omit** for trivial or self-explanatory changes
- Separate from subject with a blank line
- Use `-` bullet points for listing multiple changes
- Wrap code references in backticks
- Keep it concise — explain *why*, not *what* (the diff shows the what)

### Trailer rules

- **Never** add `Co-Authored-By` from AI agents (Claude, OpenCode, Copilot, etc.)
- `Co-Authored-By` is acceptable only for real human co-authors

### If `$ARGUMENTS` is provided

- If it looks like a full commit message, use it as-is (still apply formatting rules)
- If it's a hint or scope description, use it to guide the subject and body

## Step 3 — Confirm & Commit

1. Show the drafted commit message to the user in a code block
2. Use `AskUserQuestion` to confirm. Offer options:
   - **Yes** — commit as drafted
   - **Edit** — let the user provide a revised message
   - **Abort** — cancel
3. On confirmation, execute the commit using a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

4. Run `git status` after the commit to verify success and show the result.
