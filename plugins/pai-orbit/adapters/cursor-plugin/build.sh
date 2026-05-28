#!/usr/bin/env bash
# Cursor plugin adapter — full-fidelity (within Cursor platform limits).
# Emits dist/cursor-plugin/pai-orbit/ per Cursor plugin format:
#   .cursor-plugin/plugin.json, rules/, commands/, skills/, agents/, hooks/, scripts/, templates/
set -euo pipefail

ADAPTER_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$ADAPTER_DIR/../.." && pwd)"

CORE_DIR="${CORE_DIR:-$PLUGIN_DIR/core}"
DIST_ROOT="${DIST_ROOT:-$PLUGIN_DIR/dist/cursor-plugin}"
DIST_DIR="${DIST_DIR:-$DIST_ROOT/pai-orbit}"

if [ ! -d "$CORE_DIR" ]; then
  echo "cursor-plugin adapter: CORE_DIR not found: $CORE_DIR" >&2
  exit 1
fi

# First non-empty line of a mode file → human-readable description for frontmatter.
mode_description() {
  local file="$1"
  grep -m1 -v '^[[:space:]]*$' "$file" | sed 's/^#\+ *//' | sed 's/"/\\"/g'
}

rm -rf "$DIST_ROOT"
mkdir -p "$DIST_DIR/.cursor-plugin" \
         "$DIST_DIR/rules" \
         "$DIST_DIR/commands" \
         "$DIST_DIR/skills" \
         "$DIST_DIR/agents" \
         "$DIST_DIR/hooks" \
         "$DIST_DIR/scripts"

# plugin.json — derived from core/plugin.json with Cursor-specific keywords
core_version="$(python3 -c "import json; print(json.load(open('$CORE_DIR/plugin.json'))['version'])" 2>/dev/null || echo "1.1.0")"
cat > "$DIST_DIR/.cursor-plugin/plugin.json" <<EOF
{
  "name": "pai-orbit",
  "version": "${core_version}",
  "description": "Structured development methodology: groom, design, build, review, deploy",
  "author": {
    "name": "Pratham Software (PSI)",
    "email": "pai-orbit@thepsi.com"
  },
  "homepage": "https://github.com/the-psi/pai-orbit",
  "repository": "https://github.com/the-psi/pai-orbit",
  "license": "MIT",
  "keywords": ["methodology", "pmo", "workflow", "requirements", "architecture"]
}
EOF

# Modes → rules/*.mdc and commands/*.md
for mode_file in "$CORE_DIR"/modes/*.md; do
  [ -f "$mode_file" ] || continue
  mode_name="$(basename "$mode_file" .md)"
  description="$(mode_description "$mode_file")"

  {
    echo "---"
    echo "description: ${description}"
    echo "alwaysApply: false"
    echo "---"
    echo ""
    cat "$mode_file"
  } > "$DIST_DIR/rules/${mode_name}.mdc"

  {
    echo "---"
    echo "name: ${mode_name}"
    echo "description: ${description}"
    echo "---"
    echo ""
    cat "$mode_file"
  } > "$DIST_DIR/commands/${mode_name}.md"
done

# Always-on rule: point agents at per-project config
cat > "$DIST_DIR/rules/pai-orbit-project-config.mdc" <<'EOF'
---
description: Read per-project pai-orbit config for board, git, deploy, and docs settings
alwaysApply: true
---

When working in a repository that contains `.claude/pai-orbit-config.md`, read it before board, deploy, git workflow, or epic work. Use it for board URLs, branching model, deployment targets, docs home, and team roster (`.claude/team.md`). Also read `CLAUDE.md` for stack and project conventions.
EOF

# Skills — one directory per skill (native Cursor discovery)
cp -R "$CORE_DIR/skills/." "$DIST_DIR/skills/"

# Agents
cp -R "$CORE_DIR/agents/." "$DIST_DIR/agents/"

# Templates (for /setup-equivalent manual scaffolding)
cp -R "$CORE_DIR/templates" "$DIST_DIR/templates"

# Hook scripts (adapted from core; Claude-specific stdin format — see README parity notes)
for hook_script in "$CORE_DIR"/hooks/*.sh; do
  [ -f "$hook_script" ] || continue
  cp "$hook_script" "$DIST_DIR/scripts/$(basename "$hook_script")"
done
chmod +x "$DIST_DIR"/scripts/*.sh 2>/dev/null || true

# hooks.json — Cursor hook event names (scripts may need project-local copies after /setup)
cat > "$DIST_DIR/hooks/hooks.json" <<'EOF'
{
  "hooks": {
    "beforeShellExecution": [
      {
        "command": "./scripts/bash-guard.sh"
      }
    ],
    "afterFileEdit": [
      {
        "command": "./scripts/lint-python.sh"
      },
      {
        "command": "./scripts/lint-ts.sh"
      },
      {
        "command": "./scripts/arch-drift-guard.sh"
      }
    ]
  }
}
EOF

cat > "$DIST_ROOT/README.md" <<'EOF'
# pai-orbit — Cursor plugin adapter

Full Cursor plugin build of pai-orbit. Install as a **user-level or team marketplace plugin**, not by copying into project `.cursor/`.

## Layout

```
dist/cursor-plugin/pai-orbit/
├── .cursor-plugin/plugin.json
├── rules/           # modes as .mdc (alwaysApply: false) + project-config rule
├── commands/        # modes as invocable /commands
├── skills/          # one SKILL.md per skill
├── agents/
├── hooks/hooks.json
├── scripts/         # hook shell scripts
└── templates/
```

## Install (local development)

**Windows (PowerShell):**

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.cursor\plugins\local" | Out-Null
cmd /c mklink /D "$env:USERPROFILE\.cursor\plugins\local\pai-orbit" "D:\path\to\pai-orbit\plugins\pai-orbit\dist\cursor-plugin\pai-orbit"
```

**macOS / Linux:**

```bash
mkdir -p ~/.cursor/plugins/local
ln -sf ~/src/pai-orbit/plugins/pai-orbit/dist/cursor-plugin/pai-orbit ~/.cursor/plugins/local/pai-orbit
```

Reload Cursor (Command Palette → Developer: Reload Window). Verify rules and skills under **Settings → Rules**.

## Legacy install

If you cannot use the plugin format, the lossy bundle remains at `dist/cursor/` (copy `.cursor/rules` into your project).

**Do not** install both the user-level plugin and committed legacy rules — duplicate mode guidance will conflict.

## Parity vs Claude Code

| Feature | Claude Code | Cursor plugin |
|---------|-------------|---------------|
| `/setup` interactive board query | Full | Partial — use setup skill + templates manually |
| Live `/board` label resolution | Full | Depends on agent + CLI |
| Hook blocking (bash-guard) | PreToolUse | `beforeShellExecution` — script expects Claude stdin JSON; test per Cursor version |
| Subagent parallel tasks | Yes | Cursor subagents — test per version |

## Rebuild

```bash
bash plugins/pai-orbit/build.sh
```
EOF

echo "cursor-plugin: built $DIST_DIR"
