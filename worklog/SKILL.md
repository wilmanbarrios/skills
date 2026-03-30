---
name: worklog
description: >-
  Review and organize your daily work log. Auto-installs a hook that captures
  every prompt from ~/Code/Work/ projects into ~/.claude/worklog/YYYYMMDD.md.
  TRIGGER when: user invokes /worklog or asks to see their work log / diary.
  DO NOT TRIGGER when: user asks about git log or commit history.
version: 1.1.0
effort: medium
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(cat *), Bash(cp *), Bash(chmod *), Bash(ls *), Bash(date *), Edit, Write
---

## Input

$ARGUMENTS = one of:

- **Empty** → full day organized worklog (today)
- **Date** → `20260318` or `2026-03-18`
- **`week`** → weekly summary (last 7 days)
- **Time range** → `9am - 1pm`, `14:00 - 17:30`, `10am - 3:30pm` (filters today's entries to that window)

## Step 0 — Auto-setup Hook

Check if the worklog hook is already installed. This step runs silently unless installation is needed.

### 0a. Read current settings

Read `~/.claude/settings.json`. If it doesn't exist, treat it as `{}`.

### 0b. Prerequisites

The hook requires `jq` to parse prompt input. If `jq` is not installed, the hook will silently skip logging. Ensure `jq` is available before proceeding.

### 0c. Check for existing hook

Look for a `UserPromptSubmit` hook whose command contains `worklog`. If found, skip to Step 1.

### 0d. Install the hook

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

## Step 1 — Determine Target Date(s) and Time Range

Parse `$ARGUMENTS`:

- **Empty** → today's date (`YYYYMMDD`), no time filter
- **`week`** → last 7 days (today through 6 days ago)
- **Date string** → normalize to `YYYYMMDD` (accept `YYYY-MM-DD` or `YYYYMMDD`)
- **Time range** → today's date + filter entries to that window. Parse formats:
  - `9am - 1pm`, `9:30am - 2pm`, `09:00 - 13:00`, `2 - 7:30pm`
  - Convert to 24h for comparison against the `HH:MM` timestamps in entries
  - If only one boundary has am/pm, infer the other (e.g. `2 - 7:30pm` → both PM)

## Step 2 — Read Raw Entries

For each target date, read `~/.claude/worklog/YYYYMMDD.md`.

If no file exists for the requested date(s), inform the user that there are no entries and stop.

## Step 3 — Generate Prose Report

Produce a **concise prose summary** suitable for non-technical stakeholders
(e.g. pasting into Slack, Jira, or a standup note).

Rules:
- Write 1-2 short paragraphs per project/ticket in plain English
- Lead with the ticket ID if all work is on the same ticket
- Focus on **what was accomplished**, not technical details
- Omit internal tool names, stack names, error messages, CLI commands
- No markdown formatting (no bullets, headers, or code blocks) — just plain text
- Group related work into coherent sentences instead of listing each action
- Skip automated/cron entries (monitoring loops, task notifications)
- If a time range was provided, only include entries within that window
- For `/worklog week`, produce one paragraph per day that had activity

