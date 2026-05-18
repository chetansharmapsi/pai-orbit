#!/usr/bin/env bash
# PAI-Orbit — Cursor adapter generator
#
# Reads commands/*.md and skills/*/SKILL.md, writes .cursor/rules/pai-orbit-*.mdc
# and an optional .vscode/tasks.json lint hook template.
#
# Usage (from any directory):
#   /path/to/pai-orbit/scripts/generate-cursor.sh
#       → writes to pai-orbit's own .cursor/rules/
#
#   /path/to/pai-orbit/scripts/generate-cursor.sh --output-dir /path/to/project
#       → writes to /path/to/project/.cursor/rules/ and .vscode/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAI_ORBIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PAI_ORBIT_DIR}/.cursor/rules"
VSCODE_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="${2%/}/.cursor/rules"
            VSCODE_DIR="${2%/}/.vscode"
            shift 2
            ;;
        *)
            printf "Unknown argument: %s\n" "$1" >&2
            exit 1
            ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

# ── YAML front-matter parsers ─────────────────────────────────────────────────
# All parsers read only the block between the first and second --- delimiters.

# yaml_scalar <key> <file> — extract a top-level scalar value
yaml_scalar() {
    local key="$1" file="$2"
    awk -v k="${key}:" '
        /^---$/ { c++; if (c == 2) exit; next }
        c == 1 && substr($0, 1, length(k)) == k {
            v = substr($0, length(k) + 1)
            gsub(/^ +| +$/, "", v)
            gsub(/^'"'"'|'"'"'$|^"|"$/, "", v)
            print v; exit
        }
    ' "$file"
}

# yaml_cursor_rule_type <file> — extract cursor.rule_type
yaml_cursor_rule_type() {
    local file="$1"
    awk '
        /^---$/ { c++; if (c == 2) exit; next }
        c == 1 && /^cursor:/ { in_c = 1; next }
        in_c && /^  rule_type:/ {
            v = substr($0, index($0, ":") + 2)
            gsub(/^ +| +$/, "", v)
            print v; exit
        }
        in_c && /^[^ ]/ { in_c = 0 }
    ' "$file"
}

# yaml_cursor_patterns <file> — emit attach_patterns as JSON array contents (no brackets)
yaml_cursor_patterns() {
    local file="$1"
    awk '
        /^---$/ { c++; if (c == 2) exit; next }
        c == 1 && /^cursor:/ { in_c = 1; next }
        in_c && /^  attach_patterns:/ { in_p = 1; next }
        in_p && /^    - / {
            v = substr($0, index($0, "- ") + 2)
            gsub(/^ +| +$|'"'"'|"/, "", v)
            if (n++) printf ","
            printf "\"" v "\""
        }
        in_p && !/^    / { in_p = 0 }
        in_c && /^[^ ]/ { in_c = 0 }
        END { if (n) printf "\n" }
    ' "$file"
}

# ── Content extraction ────────────────────────────────────────────────────────

# get_body <file> — return everything after the closing --- of the front-matter
get_body() {
    awk '/^---$/ { c++; if (c == 2) { found = 1; next } } found { print }' "$1"
}

# get_content <file> — return ## Cursor section if present, else full body
get_content() {
    local body
    body=$(get_body "$1")
    if echo "$body" | grep -q "^## Cursor$"; then
        echo "$body" | awk '
            /^## Cursor$/ { found = 1; next }
            found && /^## [A-Z]/ { exit }
            found { print }
        '
    else
        echo "$body"
    fi
}

# ── Rule writers ──────────────────────────────────────────────────────────────

write_rule() {
    local src="$1"
    local name rule_type description

    name=$(yaml_scalar "name" "$src")
    rule_type=$(yaml_cursor_rule_type "$src")
    description=$(yaml_scalar "description" "$src")

    # Skip files without cursor config
    [[ -z "$name" || -z "$rule_type" ]] && return 0

    local out="${OUTPUT_DIR}/pai-orbit-${name}.mdc"
    local content
    content=$(get_content "$src")

    {
        printf -- "---\n"
        printf "description: %s\n" "$description"
        case "$rule_type" in
            always)
                printf "alwaysApply: true\n"
                ;;
            auto_attached)
                local patterns
                patterns=$(yaml_cursor_patterns "$src")
                printf "alwaysApply: false\n"
                [[ -n "$patterns" ]] && printf "globs: [%s]\n" "$patterns"
                ;;
            agent_requested)
                printf "alwaysApply: false\n"
                ;;
        esac
        printf -- "---\n"
        printf "\n%s\n" "$content"
    } > "$out"

    printf "  %-44s [%s]\n" "pai-orbit-${name}.mdc" "$rule_type"
}

write_bash_guard() {
    local out="${OUTPUT_DIR}/pai-orbit-bash-guard.mdc"
    cat > "$out" << 'RULE'
---
description: Safety guardrails — git and filesystem safety rules that apply at all times.
alwaysApply: true
---

# PAI-Orbit Safety Rules

These rules apply at all times, regardless of user instruction.

## Git safety

- **Never run `git push --force` or `git push -f`** to a protected branch (main, master, develop).
  If the user asks, explain the risk and propose `--force-with-lease` to a feature branch only.
- **Never run `git add .`, `git add -A`, or `git add --all`.**
  Always stage specific files by name. If asked to stage everything, list the files and ask for confirmation first.
- **Never run `git reset --hard`** without stating exactly what will be lost and receiving explicit confirmation.
- **Never skip hooks** (`--no-verify`). If a hook fails, diagnose and fix the underlying issue.

## Filesystem safety

- **Never run `rm -rf /`, `rm -rf ~`, `rm -rf .`, or equivalent** without listing what will be removed and
  receiving explicit confirmation. Specify explicit paths only.

## Lint on edit

After editing any Python file, suggest running: `ruff check <file>`
After editing any TypeScript or JavaScript file, suggest running: `eslint <file>`
RULE
    printf "  %-44s [always]\n" "pai-orbit-bash-guard.mdc"
}

write_vscode_tasks() {
    [[ -z "$VSCODE_DIR" ]] && return 0
    mkdir -p "$VSCODE_DIR"
    local out="${VSCODE_DIR}/tasks.json"

    if [[ -f "$out" ]]; then
        printf "  .vscode/tasks.json already exists — skipping (merge lint tasks manually)\n"
        return 0
    fi

    cat > "$out" << 'TASKS'
{
  "version": "2.0.0",
  "_comment": "PAI-Orbit lint tasks. Install the 'Run on Save' VS Code extension to trigger automatically on file save.",
  "tasks": [
    {
      "label": "pai-orbit: lint python",
      "type": "shell",
      "command": "ruff check ${file}",
      "group": "build",
      "presentation": { "reveal": "silent", "panel": "shared" },
      "problemMatcher": []
    },
    {
      "label": "pai-orbit: lint typescript",
      "type": "shell",
      "command": "eslint --fix ${file}",
      "group": "build",
      "presentation": { "reveal": "silent", "panel": "shared" },
      "problemMatcher": ["$eslint-stylish"]
    },
    {
      "label": "pai-orbit: arch drift advisory",
      "type": "shell",
      "command": ".claude/hooks/arch-drift-guard.sh",
      "group": "build",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    }
  ]
}
TASKS
    printf "  .vscode/tasks.json\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────

printf "PAI-Orbit Cursor adapter\n"
printf "Output: %s\n\n" "$OUTPUT_DIR"

for f in "$PAI_ORBIT_DIR"/commands/*.md; do
    write_rule "$f"
done

for f in "$PAI_ORBIT_DIR"/skills/*/SKILL.md; do
    write_rule "$f"
done

write_bash_guard

if [[ -n "$VSCODE_DIR" ]]; then
    printf "\nVS Code tasks:\n"
    write_vscode_tasks
fi

count=$(find "$OUTPUT_DIR" -name "pai-orbit-*.mdc" | wc -l | tr -d ' ')
printf "\n%s rules written.\n" "$count"
