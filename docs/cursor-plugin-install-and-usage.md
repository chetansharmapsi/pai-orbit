# Cursor Plugin Install and Usage

This guide explains the three supported ways to install pai-orbit in Cursor, how to use it after installation, and how to verify it is working.

## Choose one install path

Use only one of these methods at a time:

1. Local plugin install (no publish) - best for development and testing
2. Team Marketplace (private org distribution)
3. Public Cursor Marketplace (public distribution)

Do not combine these with the legacy `dist/cursor/.cursor/rules` copy method in the same project, or you may get duplicate/conflicting guidance.

---

## Method 1: Local install (no publish)

Use this for validating changes before any marketplace submission.

### 1) Build the plugin bundle

On Windows (Git Bash installed):

```powershell
& "C:\Program Files\Git\bin\bash.exe" "d:/PSIGitHub/pai-orbit/plugins/pai-orbit/build.sh"
```

Expected plugin output:

- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/.cursor-plugin/plugin.json`
- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/rules/`
- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/skills/`
- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/commands/`
- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/agents/`
- `plugins/pai-orbit/dist/cursor-plugin/pai-orbit/hooks/hooks.json`

### 2) Install locally in Cursor

#### Option A: Symlink (recommended for active development)

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.cursor\plugins\local" | Out-Null
cmd /c mklink /D "$env:USERPROFILE\.cursor\plugins\local\pai-orbit" "d:\PSIGitHub\pai-orbit\plugins\pai-orbit\dist\cursor-plugin\pai-orbit"
```

#### Option B: Copy (if symlink is blocked)

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.cursor\plugins\local" | Out-Null
Remove-Item -Recurse -Force "$env:USERPROFILE\.cursor\plugins\local\pai-orbit" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "d:\PSIGitHub\pai-orbit\plugins\pai-orbit\dist\cursor-plugin\pai-orbit" "$env:USERPROFILE\.cursor\plugins\local\pai-orbit"
```

If you use copy mode, repeat the copy after each rebuild.

### 3) Reload Cursor

Use command palette:

- `Developer: Reload Window`

---

## Method 2: Team Marketplace (private)

Use this for internal PSI rollout without public listing.

### Before you start

If you cannot find `Dashboard -> Settings -> Plugins -> Team Marketplaces`, usually one of these applies:

- your account is not an org admin
- your workspace is not on a Teams/Enterprise plan that supports Team Marketplace
- you are checking desktop settings instead of org admin dashboard

If Team Marketplace is unavailable, use Method 1 (local install) for immediate testing and switch to Team Marketplace after admin/plan access is enabled.

### Admin setup

1. Push plugin changes to a GitHub repo accessible to your org.
2. Open Cursor Dashboard -> Settings -> Plugins -> Team Marketplaces.
3. Import the repository.
4. Configure plugin availability (required/optional) for teams.

### Developer usage

1. Open Cursor Marketplace.
2. Install `pai-orbit` from your team marketplace.
3. Reload Cursor if needed.

---

## Method 3: Public Cursor Marketplace

Use this when the plugin is ready for external users.

### Pre-submit checklist

- Plugin manifest exists at `.cursor-plugin/plugin.json`
- Rules, skills, agents, and commands contain valid frontmatter
- `README.md` is present and accurate
- Build output is committed and tested locally
- License and repository visibility meet marketplace requirements

### Submit

1. Host plugin in a public GitHub repository.
2. Submit at [Cursor Marketplace Publish](https://cursor.com/marketplace/publish).
3. Address review feedback if requested.
4. After approval, install from Cursor Marketplace like any public plugin.

---

## How to use pai-orbit in Cursor after install

### Recommended project setup

In the target project, ensure these exist:

- `.cursor/pai-orbit-config.md` — board, git, deploy, docs config
- `.cursor/team.md` — team roster
- `AGENTS.md` — project stack and conventions (Cursor project guide)
- `docs/` structure (features, architecture, decisions, plans, epics)

If missing, run `/setup` in Cursor. The Cursor setup skill writes `.cursor/` config + `AGENTS.md` only — no `.claude/` or `CLAUDE.md`.

### Typical usage patterns

- Use commands where available: `/groom`, `/design`, `/build`, `/plan`, `/arch`
- Invoke skills by name when needed (for example git, review, test)
- Keep mode rules as Agent Decides unless you intentionally want always-on behavior
- Write outputs back to `docs/features/*`, `docs/architecture/`, `docs/decisions/`, `docs/plans/`

### Important

Do not install both:

- user/team plugin (`cursor-plugin`), and
- legacy project-level `.cursor/rules` copied from `dist/cursor`

Use one path per project to avoid duplicate mode instructions.

---

## Verification checklist

After installation, verify:

- `pai-orbit` rules appear in Cursor settings
- skills appear individually (not collapsed into one file)
- commands are discoverable in chat (behavior may vary by Cursor version)
- `pai-orbit-project-config` rule is present and enabled
- agent can read `.cursor/pai-orbit-config.md` when running board/deploy/git workflows

If behavior is inconsistent, reload Cursor and re-check that the local plugin path points to `dist/cursor-plugin/pai-orbit`.
