---
name: board
description: Task management — check related open stories, create issues, move cards, assign work, and close on ship using the configured board. TRIGGER before creating a story or starting/resuming work tied to a ticket, and when moving or assigning work. SKIP read-only board browsing (use the browser or CLI directly). Reads board config and team roster.
---

# Agile Board

Create, move, assign, and close tasks on the project's task board.

Reads from:
- `.cursor/pai-orbit-config.md` → `## Agile Board` section — board type, URLs, label taxonomy, column flow
- `.cursor/team.md` — team roster for default assignees and handoffs

## MCP vs shell

Before executing any board operation, check `.cursor/pai-orbit-config.md → ## MCP → board`:

- **`github`** — prefer GitHub MCP tool calls (e.g. `create_issue`, `add_issue_comment`, `update_issue`). Fall back to `gh` CLI if MCP is unavailable.
- **`linear`** — prefer Linear MCP tool calls. Fall back to `linear` CLI if MCP is unavailable.
- **`jira`** — prefer Jira MCP tool calls. Fall back to `jira` CLI if MCP is unavailable.
- **`none` or section absent** — use CLI shell commands directly; no MCP attempt.

If an MCP call fails or the server is unreachable, fall back to the equivalent shell command and note the fallback: "MCP unavailable — using shell fallback."

## Shell execution (all board types)

Adapt CLI examples to the user's active shell. Bash line continuations, `/dev/null`, loops, and `||` must not be copied verbatim into Windows PowerShell 5.1; use single-line commands or native shell syntax. Check each command's exit status before using its output or reporting success. On failure, report the error and remedy, then stop the dependent operation. These rules also apply to CLI fallbacks from MCP.

## Related open-story check

Run this check before creating a new story and at the start or resumption of ticketed work in `/groom`, `/design`, `/build`, or `/test`. The goal is to catch a changed or overlapping requirement before the developer continues against stale assumptions.

1. Resolve the in-hand ticket from the user's request or active feature context. Read its title, full description, current status, assignee, and relevant comments/history. For a proposed new story, use the proposed title and requirement as the in-hand request.
2. Query the configured board/project for its open stories, including older and newer items. Do not limit the scan to items created recently, exact title matches, or items already linked to the in-hand ticket. Exclude completed/closed items. If the configured board is an issue tracker, search its open issues for the same project/repository.
3. Compare the actual behavior, constraints, and values in the requirements, not just shared keywords. Read candidate descriptions and relevant comments; inspect related `docs/features/*` artifacts when they exist.
4. Classify plausible candidates as a requirement change/conflict, a related but separate item, a possible duplicate, or unrelated. Report each candidate's issue number, title, status, assignee, evidence for the match, the concrete difference from the in-hand requirement, and confidence (high/medium/low). If no candidates match, say the scan found none.
5. If a candidate could change the in-hand requirement or scope, pause before drafting, designing, implementing, testing, or creating the proposed story. Ask the developer whether it is a change to the current story, separate related work, a duplicate, or unrelated. Do not infer the relationship from wording or chronology alone.
6. After the developer confirms the relationship, agree on the disposition: update the existing story, keep separate stories linked, or treat the new story as a duplicate. For a confirmed requirement change, identify the canonical ticket and any existing `requirements.md`, `design.md`, implementation, and `test-plan.md` that may now be stale. Route the requirement delta through `/groom` first; then update the relevant design, implementation, and test artifacts through their normal modes before resuming work against the old requirement. Do not silently treat stale artifacts as current.
7. Show proposed ticket edits and comment text before posting. With confirmation, use the board's native relationship feature where available; otherwise add reciprocal comments referencing both issue numbers. Do not close, merge, or mark a story duplicate without explicit confirmation. Do not @mention or notify an assignee unless the developer approves the notification.
8. If the board cannot be queried, report the specific limitation and ask whether to continue without the check. Never imply the board was checked when it was not.

## Procedure

### Creating an issue

1. Read `.cursor/pai-orbit-config.md` to determine board type and column structure
2. Ask which board/project if there are multiple (e.g., Tech vs Ops, Engineering vs Product)
3. Run the Related open-story check against the proposed requirement before creating anything. If the developer confirms the proposed story is a change or duplicate, follow the confirmed disposition instead of opening a disconnected issue.
4. Ask issue type to determine labels and starting column (per the config)
5. Read `.cursor/team.md` to propose a default assignee based on issue type and role
6. Compose:
   - **Title:** short, imperative, ≤ 72 chars — mirrors commit format
   - **Body:** what + why; link to relevant docs (`docs/features/<feature>/requirements.md`, prior issues, ADRs); for features, include sub-tasks broken down by service
7. Create the issue using the configured CLI (see board type below)
8. Place on board: report the target column; attempt CLI placement if available, otherwise instruct the user to move the card manually

### Moving a card

Read the column flow from config. Common flows:
- **GitHub Projects v2:** `gh project item-edit` is unreliable for column moves — instruct browser drag is faster
- **Linear:** `linear issue update --state <state>`
- **Jira:** `jira issue transition`
- **GitLab:** boards are label-driven — each column maps to a label (scoped like `workflow::In Progress` or standalone like `To Do`). Moving a card means removing the current column label and adding the next one. Read the column→label map from `## Agile Board → columns` in config, then run the GitLab label resolution step below before applying any label.
- **Azure DevOps:** `az boards work-item update --id <N> --state "<state>"` — read the column→state map from `## Agile Board → columns` in config first; run Azure preflight below before the first call of the session. Include the configured organisation in the command.

**GitLab label resolution (always run before applying a label):**
1. Build the match list: column→label entries from config + any label name the user stated verbatim.
2. Run `glab label list --repo <namespace>/<project>` and check whether the target label exists (case-insensitive match on name).
3. If found in the live list but not in config — use it and note that the config is stale (suggest re-running `/setup`).
4. If not found at all — show the full label list to the user and ask them to confirm the intended label before proceeding. Never guess.

### Closing on ship

When a task ships:
- Close the issue with a brief comment: what was done, date, any follow-up items created
- Use `closes #N` in the final commit (via `/git`), not here

### Handoffs and assignments

Read `.cursor/team.md` for handles. Never hardcode handles in this skill — always look them up at runtime.
If a role-based assignment is requested ("assign to the mobile lead"), look up the team member in that role.

## Board-type CLI

Determined by `## Agile Board → type` in `.cursor/pai-orbit-config.md`:

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

Column→label map is read from `## Agile Board → columns` in `.cursor/pai-orbit-config.md`. If the map is absent, ask the user to supply it before moving.

**Azure DevOps:**

Use this section and Azure preflight only when `## Agile Board → type` is **Azure DevOps**. Azure commands and fields must not be required for other board types. This integration uses the Azure CLI; there is no Azure MCP path configured here.

Read organisation, project, work-item type, area path, and column→state mapping from the Azure config block. Use the roster's Azure DevOps identity for assignment; ask for missing values instead of guessing. `Team` identifies the team used to look up area settings in `/setup`; it is not a work-item field or a `--team` flag on create. Use the confirmed area path for creation, including the project root only if explicitly confirmed. For an older config without an area path, ask for it before creating and save the confirmed value.

Run Azure preflight before the first Azure operation of the session (and again if organisation/project changes).

```text
# Create in the configured area
az boards work-item create --title "<title>" --type "<work-item-type>" --org "https://dev.azure.com/<org>" --project "<project>" --area "<area-path-from-config>" --description "<body>" --assigned-to "<azure-identity-from-roster>"

# Read current state and fields
az boards work-item show --id <N> --org "https://dev.azure.com/<org>"

# Move card (state transition)
az boards work-item update --id <N> --state "<next-column-state>" --org "https://dev.azure.com/<org>"

# Assign or hand off an existing item
az boards work-item update --id <N> --assigned-to "<azure-identity-from-roster>" --org "https://dev.azure.com/<org>"

# Comment
az boards work-item update --id <N> --discussion "<text>" --org "https://dev.azure.com/<org>"

# Close using the confirmed Closing state
az boards work-item update --id <N> --state "<closing-state-from-config>" --org "https://dev.azure.com/<org>"
```

Before updating an existing item, read it and confirm its project and work-item type. If the type differs from the configured type, confirm its valid state mapping before a transition. Preserve its area and iteration during moves, comments, assignments, and closing unless the user explicitly requests a change. Do not derive an iteration from Team or Area path.

Read `columns` and `Closing state` from `## Agile Board` in `.cursor/pai-orbit-config.md`. Ask for a missing mapping before moving; for an older config without `Closing state`, confirm it from the existing mapping or ask the user before closing. Do not infer a terminal state from the last active column. If several columns share a state, report the state change and explain that exact column placement may require a manual move.

After a successful write, read the item back and verify the requested fields or discussion before reporting completion. If verification fails, report that the write succeeded but verification is incomplete; do not blindly retry creates or comments and produce duplicates.

## Azure preflight

Shared by `/setup` and `/board`, only for Azure DevOps. Run these checks in order and inspect each exit status before proceeding:

1. Run `az --version`. If the executable is missing or fails, report the error and ask the user to install or repair Azure CLI, then retry.
2. Run `az extension show --name azure-devops`. If the extension is missing, report `az extension add --name azure-devops` as the remedy and stop. For other errors, report the actual error rather than assuming the extension is absent.
3. Probe access to the configured project with `az devops project show --org "https://dev.azure.com/<org>" --project "<project>" -o none`. A successful `az account show` alone does not prove Azure DevOps access. If the probe fails, stop and report the actual error. For a missing or expired credential, suggest `az devops login --organization "https://dev.azure.com/<org>"` or `AZURE_DEVOPS_EXT_PAT`; for permission, project, or network errors, ask the user to correct the corresponding access or configuration. Never request a token in chat or write one into project config.

Use native exit-status handling, without Bash-only redirection or `|| echo`. Never report a board operation as applied after a failed preflight or command.

## Conventions (always apply)

- `refs #N` in commits during development; `closes #N` in the final shipping commit only
- One feature = one issue; sub-tasks go in the body unless they ship independently
- Do not close issues autonomously without confirming with the user
