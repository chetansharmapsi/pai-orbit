# pai-orbit (plugin)

This directory is the pai-orbit plugin source. It is structured as a tool-agnostic `core/` plus per-tool `adapters/` that compile to `dist/`.

```
plugins/pai-orbit/
├── core/                       # tool-agnostic source of truth
│   ├── plugin.json             # canonical plugin manifest (used by Claude Code adapter)
│   ├── modes/                  # the working modes — /arch, /build, /design, …
│   ├── skills/                 # operational procedures
│   ├── agents/                 # named sub-agents
│   ├── hooks/                  # PreToolUse / PostToolUse shell hooks
│   └── templates/              # scaffolds emitted by /setup
├── adapters/
│   ├── claude-code/build.sh    # full-fidelity; emits Claude Code plugin layout
│   ├── cursor/build.sh         # lossy; emits .cursor/rules/*.mdc
│   ├── copilot/build.sh        # lossy; emits .github/copilot-instructions.md
│   └── codex/build.sh          # experimental; emits AGENTS.md
├── dist/                       # built outputs (committed)
│   ├── claude-code/
│   ├── cursor/
│   ├── copilot/
│   └── codex/
└── build.sh                    # runs every adapter in sequence
```

## Building

```bash
bash plugins/pai-orbit/build.sh
```

Each adapter clears its own `dist/<adapter>/` subdir and rebuilds from `core/`. The build is intended to be deterministic — `git status` after a no-op rebuild should be clean. If it isn't, the adapter is non-deterministic and should be fixed.

## Adapter fidelity

| Adapter | Modes | Skills | Agents | Hooks | Templates |
|---------|-------|--------|--------|-------|-----------|
| claude-code | ✅ as `/commands/` | ✅ | ✅ | ✅ | ✅ |
| cursor      | ⚠️ as rules (`.cursor/rules/*.mdc`) | ⚠️ as one rule | ❌ | ❌ | ✅ (verbatim) |
| copilot     | ⚠️ as instructions | ⚠️ as appendix | ❌ | ❌ | ❌ |
| codex       | ⚠️ as instructions | ⚠️ as appendix | ❌ | ❌ | ❌ |

`⚠️` means "carried over as reference text only" — the receiving tool has no command/skill/agent invocation system. See each `dist/<adapter>/README.md` for specifics.

## Adding a new adapter

1. `mkdir plugins/pai-orbit/adapters/<tool>` and write a `build.sh`.
2. Read from `${CORE_DIR:-../../core}`, write to `${DIST_DIR:-../../dist/<tool>}`.
3. Emit a `dist/<tool>/README.md` documenting what was lossy.
4. The top-level `build.sh` auto-discovers it via `adapters/*/build.sh`.
