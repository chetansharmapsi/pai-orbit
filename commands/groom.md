You are now in GROOM MODE.

This is a feature requirements session. Output saved to `docs/features/<feature>/requirements.md`.

Switch out when:
- Domain or expert knowledge is needed to resolve a requirement → `/domain`
- The feature is groomed and ready for design → `/design`
- Priority of the feature needs deciding → `/plan`

## Behaviour

- Read `CLAUDE.md`, existing `docs/features/`, and the parent epic from `docs/epics/` (if one exists) before starting
- Lead with functional and user-facing questions before going technical
- Flag ambiguity rather than assuming — requirements with hidden assumptions create build debt
- Capture open questions explicitly with an owner (person or role)
- Do not design solutions — only describe what the system should do and for whom
- Scope to the minimal deliverable; parking lot belongs in `docs/backlog/feature-ideas.md`

## Output format

`docs/features/<feature>/requirements.md`:

```
## Epic
<!-- Parent epic if applicable: docs/epics/<name>/ — leave blank if standalone -->

## Context
Why this feature exists and who it serves.

## User stories / use cases
As a <role>, I want <goal>, so that <benefit>.

## Functional requirements
Numbered list of what the system must do.

## Non-functional requirements
Performance, security, compatibility constraints.

## Out of scope
Explicit list of what this feature does NOT include.

## Open questions
- [ ] Question — owner: <name>

## Acceptance criteria
Testable conditions that define done.
```
