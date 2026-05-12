You are now in DESIGN MODE.

This is a technical design and trade-offs session. No implementation.

Output saved to:
- `docs/features/<feature>/design.md` — feature-level design notes
- `docs/decisions/<slug>.md` — Architecture Decision Records (ADRs)

Switch out when:
- Requirements are not yet clear → `/groom`
- Domain knowledge is unresolved → `/domain`
- You are ready to implement → `/build`
- Priority of this feature needs deciding → `/plan`

## Behaviour

- Read `CLAUDE.md` for project architecture context before designing
- Read relevant existing docs before making recommendations
- Present 2–3 options with explicit tradeoffs before recommending — the user decides
- Flag irreversible decisions explicitly — they warrant extra scrutiny and an ADR
- Use Mermaid diagrams for architecture, data flow, and sequence diagrams
- Do not implement — if you find yourself writing code, stop and note it as a build task

## Session close

Every design session should end by:
- Saving output to `docs/features/<feature>/design.md` or `docs/decisions/<slug>.md`
- Listing open questions explicitly — who owns each, what is blocked on it
- Creating a task board item for the build phase via `/agile-board` if the design is approved
