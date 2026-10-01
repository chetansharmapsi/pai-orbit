---
mode: agent
description: "[skill] Task management — create issues, move cards, transition a ticket at mode close-out, assign work, close on ship — using the…"
tools: ["codebase", "editFiles", "runCommands", "search"]
---


# Agile Board

Create, move, assign, and close tasks on the project's task board.

Reads from:
- `.copilot/pai-orbit-config.md` → `## Agile Board` section — board type, URLs, label taxonomy, column flow
- `.copilot/pai-orbit-config.md` → `## Mode transitions` section — mode→column map and board IDs, written by `/setup`; read by `transition(mode)`
- `.copilot/team.md` — team roster for default assignees and handoffs

## MCP vs shell

Before executing any board operation, check `.copilot/pai-orbit-config.md → ## MCP → board`:

- **`github`** — prefer GitHub MCP tool calls (e.g. `create_issue`, `add_issue_comment`, `update_issue`). Fall back to `gh` CLI if MCP is unavailable.
- **`linear`** — prefer Linear MCP tool calls. Fall back to `linear` CLI if MCP is unavailable.
- **`jira`** — prefer Jira MCP tool calls. Fall back to `jira` CLI if MCP is unavailable.
- **`none` or section absent** — use CLI shell commands directly; no MCP attempt.

If an MCP call fails or the server is unreachable, fall back to the equivalent shell command and note the fallback: "MCP unavailable — using shell fallback."

## Procedure

### Creating an issue

1. Read `.copilot/pai-orbit-config.md` to determine board type and column structure
2. Ask which board/project if there are multiple (e.g., Tech vs Ops, Engineering vs Product)
3. Ask issue type to determine labels and starting column (per the config)
4. Read `.copilot/team.md` to propose a default assignee based on issue type and role
5. Compose:
   - **Title:** short, imperative, ≤ 72 chars — mirrors commit format
   - **Body:** what + why; link to relevant docs (`docs/features/<feature>/requirements.md`, prior issues, ADRs); for features, include sub-tasks broken down by service
6. Create the issue using the configured CLI (see board type below)
7. Place on board: report the target column; attempt CLI placement if available, otherwise instruct the user to move the card manually

### Moving a card

Manual moves (a user asking to move a card, `/plan` reprioritisation). Mode close-out moves use `transition(mode)` below instead.

Read the column flow from config. Common flows:
- **GitHub Projects v2:** for a one-off manual move, dragging the card in the browser is usually faster; the `gh project item-edit` recipe under `transition(mode)` also works when the IDs are known
- **Linear:** `linear issue update --state <state>`
- **Jira:** `jira issue transition`
- **GitLab:** boards are label-driven — each column maps to a label (scoped like `workflow::In Progress` or standalone like `To Do`). Moving a card means removing the current column label and adding the next one. Read the column→label map from `## Agile Board → columns` in config, then run the GitLab label resolution step below before applying any label.

**GitLab label resolution (always run before applying a label):**
1. Build the match list: column→label entries from config + any label name the user stated verbatim.
2. Run `glab label list --repo <namespace>/<project>` and check whether the target label exists (case-insensitive match on name).
3. If found in the live list but not in config — use it and note that the config is stale (suggest re-running `/setup`).
4. If not found at all — show the full label list to the user and ask them to confirm the intended label before proceeding. Never guess.

### resolve_ticket()

Finds the one board ticket the current session is for. Used by `transition(mode)`; any mode may call it.

1. **Explicit** — an invocation argument (`/design 30`), a `#N` the user named in this session, or groom's entry-gate ticket.
2. **Branch** — `refs #N` / `closes #N` in `git log <main>..HEAD`.
3. **PR** — the open PR's linked issue, or `closes #N` in its body (mainly `/review`).

Stop at the first source that yields a ticket. Then:
- **0 found** → none. The caller skips quietly — no message.
- **1 found** → use it.
- **2+ found** → list them and ask "Which ticket: #12 or #30?" This is the only prompt `transition(mode)` may raise.

### transition(mode)

Moves the session's ticket to the column mapped for `mode` (`groom`, `design`, `build`, `review`) in `.copilot/pai-orbit-config.md → ## Mode transitions`. Called by those modes at close-out **after** their output is committed — no outcome here may block or undo the commit. Every path ends with at most one line of output, then returns to the calling mode, which continues its close-out.

Do **not** ask "Move issue #N?" — the move is the definition of done. Never close the issue here.

1. **Ticket.** `resolve_ticket()`. None → return silently.
2. **Map row.** Read `## Mode transitions`. Read the table **by column position** — 1st cell mode, 2nd target column name, 3rd column ID — not by header text, so hand-written tables with different headers still work.
   - Section absent → "No mode-transition map — re-run /setup to enable automatic board moves." Return.
   - No row for `mode`, or its ID blank / a `{{PLACEHOLDER}}` → "Mode transitions: no resolved column for `<mode>` — re-run /setup." Return.
   - Target is `no move` → "`<mode>`: no board move configured." Return.
3. **Target still exists.** Check the target column ID is still on the live board (same query setup uses in Step 2b). Gone → "Column '`<name>`' no longer on the board — re-run /setup." Return.
4. **Current column.** Read the ticket's state and current column (MCP → CLI; recipes below).
   - Ticket closed → "#N is closed — not moved." Return.
   - GitHub Projects: ticket not on the configured project → "#N is not on board `<name>` — add it, then re-run." Return. Never add it yourself — modes move tickets, they don't change board membership.
5. **Never backwards.** Find the current and target columns in `## Agile Board → columns` (row order = board order, left → right).
   - Current column not in the table → "#N is in '`<current>`', not in config — re-run /setup." Return.
   - Current position ≥ target position → "#N already in `<current>` (past `<target>`) — not moved." Return.
6. **Move.** Set the ticket to the target column ID (MCP → CLI). On failure, show the error and the fix: GitHub Projects `gh auth refresh -s project`; Linear an API token with write scope; Jira a user with the transition permission; GitLab a Reporter+ role. Return.
7. **Report.** "#N → `<target>`".

**Per-board recipes.** IDs come from `## Mode transitions` (board-IDs header + Column ID). Use the configured board MCP first under **MCP vs shell** above; use the CLI when the MCP is absent or has no matching tool (e.g. a GitHub MCP server without a Projects v2 item-field update tool — then GitHub Projects moves always use `gh`).

GitHub Projects v2:
```bash
# Step 4 — item ID on this project + current Status, in one call
gh api graphql -f query='
  query($o:String!,$r:String!,$n:Int!){ repository(owner:$o,name:$r){ issue(number:$n){
    state
    projectItems(first:20){ nodes{ id project{ id }
      fieldValueByName(name:"Status"){ ... on ProjectV2ItemFieldSingleSelectValue{ optionId name } }
  }}}}}' -F o=<owner> -F r=<repo> -F n=<N>
# use the node whose project.id == Project ID from config; none → "not on board"

# Step 6
gh project item-edit --id <itemId> --project-id <Project ID> \
  --field-id <Status field ID> --single-select-option-id <Column ID>
```

Linear:
```bash
linear issue update <ISSUE-ID> --state <Column ID>
```

Jira (the move is a workflow transition; jira-cli picks the transition that reaches the named status):
```bash
jira issue move <KEY> "<target column name>"
# then confirm: jira issue view <KEY> --raw | jq -r '.fields.status.id'  — must equal Column ID
```

GitLab (columns are labels; Column ID is the label name — run the label resolution step above first):
```bash
glab issue update <N> --repo <namespace>/<project> \
  --remove-label "<current column label>" --label "<Column ID>"
```

### Closing on ship

When a task ships:
- Close the issue with a brief comment: what was done, date, any follow-up items created
- Use `closes #N` in the final commit (via `/git`), not here

### Handoffs and assignments

Read `.copilot/team.md` for handles. Never hardcode handles in this skill — always look them up at runtime.
If a role-based assignment is requested ("assign to the mobile lead"), look up the team member in that role.

## Board-type CLI

Determined by `## Agile Board → type` in `.copilot/pai-orbit-config.md`:

**GitHub Issues:**
```bash
gh issue create \
  --repo <owner>/<repo> \
  --title "<title>" \
  --body "<body>" \
  --label "<labels>" \
  --assignee "<handle>"
```

**Linear:**
```bash
linear issue create --title "<title>" --description "<body>" --team <team-id> --assignee <user-id>
```

**Jira:**
```bash
jira issue create --project <key> --summary "<title>" --description "<body>" --assignee <user-id>
```

**GitLab:**
```bash
# Create
glab issue create \
  --repo <namespace>/<project> \
  --title "<title>" \
  --description "<body>" \
  --label "<labels>" \
  --assignee "<handle>"

# Move card (swap column label — scoped or standalone)
glab issue update <issue-id> \
  --repo <namespace>/<project> \
  --remove-label "<current-column-label>" \
  --label "<next-column-label>"

# Close
glab issue close <issue-id> --repo <namespace>/<project>
```

Column→label map is read from `## Agile Board → columns` in `.copilot/pai-orbit-config.md`. If the map is absent, ask the user to supply it before moving.

## Conventions (always apply)

- `refs #N` in commits during development; `closes #N` in the final shipping commit only
- One feature = one issue; sub-tasks go in the body unless they ship independently
- Do not close issues autonomously without confirming with the user
