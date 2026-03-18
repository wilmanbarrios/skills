#!/usr/bin/env bash
# Auto-bump skill versions based on staged changes.
# Runs as a PreToolUse hook on Bash(git commit*).

set -euo pipefail

# Find modified (not added) SKILL.md files in the staging area
modified_skills=$(git diff --cached --diff-filter=MR --name-only -- '**/SKILL.md' 2>/dev/null || true)

if [[ -z "$modified_skills" ]]; then
  exit 0
fi

bumped=()

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Read current version from the staged file content
  current_version=$(git show ":$file" | grep -m1 '^version:' | sed 's/version:[[:space:]]*//' || true)

  if [[ -z "$current_version" ]]; then
    continue
  fi

  # Check if only the version line changed — means manual bump, skip
  diff_output=$(git diff --cached -- "$file")
  changed_minus=$(echo "$diff_output" | grep -c '^-[^-]' || true)
  changed_plus=$(echo "$diff_output" | grep -c '^+[^+]' || true)

  if [[ "$changed_minus" -eq 1 && "$changed_plus" -eq 1 ]]; then
    only_version_minus=$(echo "$diff_output" | grep '^-[^-]' | grep -c '^-version:' || true)
    only_version_plus=$(echo "$diff_output" | grep '^+[^+]' | grep -c '^+version:' || true)
    if [[ "$only_version_minus" -eq 1 && "$only_version_plus" -eq 1 ]]; then
      continue
    fi
  fi

  # Parse semver components
  IFS='.' read -r major minor patch <<< "$current_version"
  major=${major:-0}
  minor=${minor:-0}
  patch=${patch:-0}

  # Classify the change from the staged diff
  bump_type="patch"

  # Check for major: removed/changed name, allowed-tools, or disable-model-invocation
  if echo "$diff_output" | grep -qE '^-(name|allowed-tools|disable-model-invocation):'; then
    bump_type="major"
  # Check for minor: added new Step sections or sub-sections
  elif echo "$diff_output" | grep -qE '^\+## Step|^\+### '; then
    bump_type="minor"
  fi

  # Compute new version
  case "$bump_type" in
    major)
      new_version="$((major + 1)).0.0"
      ;;
    minor)
      new_version="${major}.$((minor + 1)).0"
      ;;
    patch)
      new_version="${major}.${minor}.$((patch + 1))"
      ;;
  esac

  # Update the version in the working tree file
  sed -i '' "s/^version: ${current_version}/version: ${new_version}/" "$file"

  # Re-stage
  git add "$file"

  # Extract skill name from path (parent directory name)
  skill_name=$(echo "$file" | sed 's|/SKILL.md$||' | sed 's|.*/||')

  bumped+=("  ${skill_name}: ${current_version} -> ${new_version} (${bump_type})")

done <<< "$modified_skills"

if [[ ${#bumped[@]} -gt 0 ]]; then
  message="Auto-bumped skill versions:"
  for line in "${bumped[@]}"; do
    message="${message}\n${line}"
  done
  printf '{"systemMessage": "%s"}\n' "$message"
fi
