# Multi-Tool Compatibility

**Status:** Draft
**Owner:** Punit Singhal
**Last Updated:** 2026-05-18

## Summary
Extend pai-orbit so the same mode discipline and operational skills work in Cursor and OpenAI Codex CLI, not just Claude Code — enabling teams to use whichever AI coding tool they prefer without losing the methodology.

## Requirements
1. pai-orbit's command headspaces (`/build`, `/design`, `/plan`, etc.) are available as native constructs in Cursor and Codex CLI
2. Skills (`/git`, `/deploy`, `/review`, etc.) are available in Cursor and Codex CLI
3. Hooks (bash-guard, lint, arch-drift-guard) fire on the equivalent tool events in Cursor; degrade gracefully where Codex CLI has no hook system
4. `/setup` detects or asks which tool(s) are in use and generates the right config files for each
5. A single source of truth in this repo drives all tool-specific output — no parallel hand-maintained files

## User Stories
- As a developer using Cursor, I want `/build` and `/design` modes to enforce the same headspace discipline as in Claude Code, so that I don't lose the methodology when switching editors.
- As a developer using Codex CLI, I want pai-orbit's instructions to load automatically from `AGENTS.md`, so that I get mode-aware behaviour without manual setup.
- As a team with mixed tooling, I want `/setup` to generate config for all tools in use, so that every engineer gets the same experience regardless of which tool they run.

## Features
| Feature | Status |
|---------|--------|
| canonical-spec | Not started |
| cursor-adapter | Not started |
| codex-adapter | Not started |
| setup-multi-tool | Not started |

## Success Metrics
- A Cursor project with pai-orbit rules active enforces the same mode headspace as Claude Code
- A Codex CLI session in a pai-orbit project reads AGENTS.md and behaves mode-aware
- `/setup` generates correct output for Claude Code, Cursor, and Codex CLI from a single run
- No pai-orbit content is duplicated — all tool outputs are generated from the canonical `.md` source files

## Decisions
- **Generator vs parallel files:** Generator approach — single source of truth in `commands/*.md` and `skills/*/SKILL.md`; generator produces Cursor and Codex artefacts. See `docs/features/multi-tool-compat/design.md` D6.
- **Claude adapter strategy (Phase 1):** Claude reads source files directly (native format). Generator does not produce Claude output yet. Migration to full Option B deferred to a future phase when a 4th tool warrants it.
- **Cursor modes:** Surfaced as `agent_requested` Cursor rules — no custom slash commands. User types "enter build mode" or task context triggers the rule automatically.
- **Codex CLI hooks:** Terminal wrapper scripts (`pai` CLI) handle pre/post execution hooks. No native hook system in Codex CLI.

## Open Questions
- [ ] Should Phase 1 (canonical front-matter) be done in one PR across all commands + skills, or incrementally? — owner: Punit Singhal
- [ ] Which skills should use `auto_attached` Cursor rule type vs `agent_requested`? (e.g. data-model auto-attaches to `*.sql`) — owner: Punit Singhal
- [ ] `pai` CLI wrapper: how does it detect which Codex CLI binary is installed (`codex` vs `openai`)? — owner: Punit Singhal
