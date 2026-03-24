---
name: git-branch
description: >-
  Create well-named git branches with consistent naming conventions.
  Guides through branch type, description, and target branch selection.
  TRIGGER when: user invokes /git:branch, asks to create a new branch,
  or wants to start working on a new feature/fix/task.
  DO NOT TRIGGER when: user wants to switch to an existing branch,
  delete a branch, or rename a branch.
version: 2.0.1
effort: medium
disable-model-invocation: true
allowed-tools: Bash(git branch *), Bash(git switch *), Bash(git status*), Bash(git stash *), Bash(git fetch *)
---

## Input

$ARGUMENTS = optional hint describing the branch purpose, type, or ticket.

## Step 1 — Gather Context

Run all of these in parallel:

### 1a. Working Tree Status

```bash
git status --short
```

Note whether there are uncommitted changes — they will be carried to the new branch (or stashed if needed).

### 1b. Detect Target Branch Candidates

```bash
git branch -a
```

Filter the output for common base branches:

- Match these names: `main`, `master`, `develop`, `development`, `dev`, `staging`, `stage`, `production`, `prod`, and any `release/*` branches
- Strip `remotes/origin/` prefixes and deduplicate (if a branch exists both locally and on the remote, keep one entry)
- Sort by priority: `main`/`master` → `develop`/`dev`/`development` → `staging`/`stage` → `production`/`prod` → `release/*`
- If no candidates are found, fall back to the current branch

## Step 2 — Select Branch Type

Use `AskUserQuestion` to ask "What type of branch?". Options:

| Option | Description |
|--------|-------------|
| `feature` | New functionality or capability |
| `fix` | Bug fix |
| `task` | Non-feature work (refactoring, config, chores) |
| `hotfix` | Urgent production fix |

If `$ARGUMENTS` clearly implies a type (e.g., "fix the login bug" → `fix`), mark that option as recommended.

> If the user needs `pre-release` or `release`, they can type it via "Other".

## Step 3 — Describe the Branch

Use `AskUserQuestion` to ask "Brief description of the branch?". Provide 2 options:

- If `$ARGUMENTS` contains a useful hint, propose a pre-built slug as the first (recommended) option
- A second option inviting the user to type their own description via "Other"

Rules for building the slug:

1. **Always translate to English** regardless of input language
2. **Extract ticket ID** if present — pattern: one or more uppercase letters, a hyphen, one or more digits (e.g., `OTH-478`, `FEAT-12`). Keep the ticket ID separate; it goes in the branch name prefix, not the slug.
3. **Convert to kebab-case**: lowercase, hyphens between words, 3–5 words, max ~50 characters
4. Strip filler words (the, a, an, for, to) when they push past the limit

## Step 4 — Confirm & Create

Construct the full branch name:

- **With ticket**: `{type}/{TICKET-ID}-{slug}` (e.g., `feature/OTH-478-add-cdk-infrastructure`)
- **Without ticket**: `{type}/{slug}` (e.g., `fix/resolve-login-timeout`)

Use `AskUserQuestion` to confirm. List each target branch candidate as an option. The first (recommended) option should use a `preview` showing:

```
Branch:  {full-branch-name}
From:    {target-branch}
Command: git switch -c {full-branch-name} {target-branch}

Note: Your uncommitted changes will be carried to the new branch.
```

(Omit the "Note" line if there are no uncommitted changes.)

On confirmation, run:

```bash
git switch -c {branch-name} {target-branch}
```

### Fallback: uncommitted changes conflict

If `git switch` fails because of uncommitted changes that would be overwritten:

```bash
git stash
git switch -c {branch-name} {target-branch}
git stash pop
```

If `git stash pop` reports conflicts, inform the user that their changes are safe in the stash (`git stash list`) and they need to resolve conflicts manually. Do **not** drop the stash.

### Edge case: branch already exists

If the branch name already exists, inform the user and ask for an alternative description (go back to Step 3).

### Finish

Run `git status` to verify the new branch is active and show the result.
