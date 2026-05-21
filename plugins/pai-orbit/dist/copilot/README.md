# pai-orbit — GitHub Copilot adapter

This is a **lossy** build of pai-orbit for GitHub Copilot.

## What's here

- `.github/copilot-instructions.md` — a single concatenated instructions file containing all pai-orbit modes and a skills appendix.

## What's lost vs the Claude Code plugin

- **No command system.** Modes are reference instructions only, not invokable commands.
- **No skill invocation.** Skills become reference documents.
- **No agents, no hooks, no scaffolding templates.** Copilot's custom-instructions surface is a single Markdown file.

## How to install

Copy `.github/copilot-instructions.md` into your project's `.github/` directory (or merge with an existing file). Copilot Chat will pick it up automatically in supported editors.
