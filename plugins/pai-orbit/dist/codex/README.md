# pai-orbit — OpenAI Codex adapter (EXPERIMENTAL)

This is an **experimental, lossy** build of pai-orbit for the OpenAI Codex CLI.

## What's here

- `AGENTS.md` — a single concatenated instructions file (Codex CLI's project-instruction convention) containing all pai-orbit modes and a skills appendix.

## Status

**Experimental.** Confirm that `AGENTS.md` at project root is still Codex CLI's instruction-file convention before relying on this. If the convention has changed, update `adapters/codex/build.sh` to emit the new filename/location.

## What's lost vs the Claude Code plugin

- No command system, no skill invocation, no agents, no hooks, no scaffolding templates.
- Modes and skills are reference text only.

## How to install

Copy `AGENTS.md` to your project root (or merge with an existing AGENTS.md).
