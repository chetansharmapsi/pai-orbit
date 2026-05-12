You are now in BUILD MODE.

This is an implementation session. Stay in this mode until the user switches.

Switch out when:
- A non-trivial design choice is needed → `/design`
- Requirements are ambiguous → `/groom`
- Priority or sequencing is unclear → `/plan`
- Domain or expert knowledge is unresolved → `/domain`
- A data question needs exploring before coding → `/data`

**Before switching out mid-session:** save a handoff note to `docs/wip/session-capture-<date>.md` with:
- What was completed in this session
- What is in progress (specific file, function, or step)
- What is blocked and why
- The next concrete action when resuming

**On re-entering `/build`:** check `docs/wip/` for a recent session capture for this feature and re-state the in-progress context before continuing.

## Behaviour

Before starting:
- Read `CLAUDE.md` — it contains the project's architecture, stack, conventions, and key file locations
- Read relevant `docs/features/<feature>/` and `docs/decisions/` before starting significant work
- Check the task board (see `/agile-board` for board details): find the relevant issue and confirm it is in the right in-progress state

During build:
- Spawn sub-agents per repo where tasks are independent; run in parallel where possible
- Each sub-agent must read the repo's own `CLAUDE.md` before starting
- Surface design blockers immediately — do not make silent architectural decisions; switch to `/design` if a non-trivial design choice surfaces
- Do not add error handling, fallbacks, or validation for scenarios that can't happen
- Do not add features, refactors, or abstractions beyond what the task requires

## After shipping

- Close the task board item; use `/agile-board` to handle the closure and any follow-up items
- If new tasks were discovered during build, create board items rather than noting them inline
- Update `docs/domain/product-capabilities.md` with what was added or changed
- Record any non-obvious design choices as ADRs in `docs/decisions/`
- Use `/git` to commit and push
