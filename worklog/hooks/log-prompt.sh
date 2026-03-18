#!/bin/bash
# Worklog hook — logs every prompt to ~/.claude/worklog/YYYYMMDD.md
# Designed for UserPromptSubmit hook. Only logs prompts from ~/Code/work/*.
# Always exits 0 to never block the user.

INPUT=$(cat) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null) || exit 0
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || exit 0

[ -z "$PROMPT" ] && exit 0

# Only log prompts from work projects
WORK_DIR="$HOME/Code/work"
case "$CWD" in "$WORK_DIR"/*) ;; *) exit 0 ;; esac

PROJECT=$(basename "${CWD:-unknown}")
DATE=$(date +%Y%m%d)
TIME=$(date +%H:%M)

DIARY_DIR="$HOME/.claude/worklog"
DIARY_FILE="$DIARY_DIR/$DATE.md"
mkdir -p "$DIARY_DIR" 2>/dev/null || exit 0

if [ ! -f "$DIARY_FILE" ]; then
  printf "# Worklog — %s\n\n" "$(date +%Y-%m-%d)" > "$DIARY_FILE" 2>/dev/null || exit 0
fi

SUMMARY=$(printf '%s' "$PROMPT" | head -1 | cut -c1-200)
printf -- '- **%s** | `%s` | %s\n' "$TIME" "$PROJECT" "$SUMMARY" >> "$DIARY_FILE" 2>/dev/null
exit 0
