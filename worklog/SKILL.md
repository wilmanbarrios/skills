---
name: worklog
description: >-
  Review and organize your daily work log. Auto-installs a hook that captures
  every prompt from ~/Code/Work/ projects into ~/.claude/worklog/YYYYMMDD.md.
  TRIGGER when: user invokes /worklog or asks to see their work log / diary.
  DO NOT TRIGGER when: user asks about git log or commit history.
version: 1.0.0
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(cat *), Bash(cp *), Bash(chmod *), Bash(ls *), Bash(date *), Edit, Write, AskUserQuestion
---

## Input

$ARGUMENTS = optional date (`20260318` or `2026-03-18`) or `week` for weekly summary.

## Step 0 — Auto-setup Hook

Check if the worklog hook is already installed. This step runs silently unless installation is needed.

### 0a. Read current settings

Read `~/.claude/settings.json`. If it doesn't exist, treat it as `{}`.

### 0b. Check for existing hook

Look for a `UserPromptSubmit` hook whose command contains `worklog`. If found, skip to Step 1.

### 0c. Install the hook

1. Create `~/.claude/hooks/` directory if it doesn't exist
2. Copy the hook script from **this skill's directory** (`worklog/hooks/log-prompt.sh`) to `~/.claude/hooks/worklog.sh`
3. Make it executable: `chmod +x ~/.claude/hooks/worklog.sh`
4. Read the current `~/.claude/settings.json` (or start from `{}`)
5. Merge this hook configuration into the existing settings, preserving all existing hooks and settings:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/worklog.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Important**: If `hooks.UserPromptSubmit` already has entries, append to the array — do not replace.

6. Write the updated settings back to `~/.claude/settings.json`
7. Inform the user: "Worklog hook installed. It will start capturing prompts from `~/Code/Work/` projects in your next session."

## Step 1 — Determine Target Date(s)

Parse `$ARGUMENTS`:

- **Empty** → today's date (`YYYYMMDD`)
- **`week`** → last 7 days (today through 6 days ago)
- **Date string** → normalize to `YYYYMMDD` (accept `YYYY-MM-DD` or `YYYYMMDD`)

## Step 2 — Read Raw Entries

For each target date, read `~/.claude/worklog/YYYYMMDD.md`.

If no file exists for the requested date(s), inform the user that there are no entries and stop.

## Step 3 — Organize and Present

Group entries by:

1. **Project** (the value between backticks in each entry)
2. **Feature/task** — infer macro-level tasks by analyzing prompt similarity within each project

Present the organized summary in this format:

```markdown
# Worklog — YYYY-MM-DD

## project-name | Feature/Task Description
- **HH:MM** — Brief description derived from the prompt
- **HH:MM** — Another entry

## other-project | Another Feature
- **HH:MM** — Description
```

For `/worklog week`, use this format:

```markdown
# Weekly Worklog — YYYY-MM-DD to YYYY-MM-DD

## YYYY-MM-DD (Day)

### project-name | Feature
- **HH:MM** — Description

---

## YYYY-MM-DD (Day)
...
```

### Guidelines for organizing

- Preserve all timestamps exactly as recorded
- Derive concise descriptions from the raw prompt text (clean up, don't invent)
- Group related prompts into features/tasks based on semantic similarity
- Name features descriptively (e.g., "Payment Refunds", "UI Fixes", "API Migration")

## Step 4 — Offer to Save

Use `AskUserQuestion` to ask the user:

- **Save** (Recommended) — Overwrite the raw file with the organized version
- **Keep raw** — Leave the original file unchanged
- **Copy** — Save organized version as `YYYYMMDD-organized.md` alongside the original

For weekly summaries, offer to save as `week-YYYYMMDD.md`.
