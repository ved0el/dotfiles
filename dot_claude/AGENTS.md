# AGENTS.md — Claude Code (dot_claude/ + the Claude parts of the bootstraps)

Scoped to `dot_claude/`, `.chezmoitemplates/claude-settings.json`,
`run_onchange_after_20-install-claude.*` and `run_after_update-claude-plugins.*`. The "why"
behind each rule is in its commit (`git log -S`). Repo-wide rules: root `AGENTS.md`.

## Settings
- **`~/.claude/settings.json` is MERGED, not replaced.** `dot_claude/modify_settings.json` (a
  `chezmoi:modify-template`) merges the curated keys from `.chezmoitemplates/claude-settings.json`
  into the live file: objects merge one level deep with the curated entry winning,
  `permissions.allow` is a union, `hooks` and scalars are replaced, live-only keys are kept.
  - Machine-local edits survive `cza`; a curated value Claude overwrote (e.g. a marketplace's
    `autoUpdate`) comes back.
  - Deleting a curated entry does NOT delete it live — remove it by hand too.
  - Output is sorted `toPrettyJson`; the first apply after Claude reorders keys shows `M`.
  - Never symlink it: Claude saves by rename, replacing the link.
- The template is a template only so `statusLine.command` can branch per OS.
- **No `model` key**: picking "Default" in `/model` deletes the key, so a tracked value drifts.
- **`~/.claude/CLAUDE.md` is managed** (`dot_claude/CLAUDE.md`): the `@RTK.md` import (so rtk
  finds it present) + the codegraph rule. `RTK.md` stays rtk-written and machine-local.

## Claude Code install
- Bootstrap part 2 installs it only when `claude` is missing, with the official native one-liners
  VERBATIM (`irm https://claude.ai/install.ps1 | iex`, `curl -fsSL https://claude.ai/install.sh |
  bash`) — they auto-update. **NEVER winget/brew/npm** (no auto-update; hook-enforced).
- On Windows it runs inside `& { … }` so the installer's `StrictMode`/`Stop` stay in its scope.
- It must exist before the plugin loop: that loop is guarded on `claude` and would never retry.

## Marketplaces & plugins — `cza` installs what's missing, `czu` updates what's there
- **Install (part 2):** `marketplace add` for each `extraKnownMarketplaces` entry missing from
  `claude plugin marketplace list --json`, then `claude plugin install -y` for each missing
  `enabledPlugins` id. Both lists are local reads (zero network when complete). `-y` is required
  (no TTY). Every call is `|| echo` / `try/catch`.
- **Update (`run_after_update-claude-plugins.*`):** `claude plugin marketplace update` + `claude
  plugin update <id>` per plugin. Its existence is gated in `.chezmoiignore` on
  `.chezmoi.command == "update"`, so `cza` stays offline and `status` shows no permanent `R`.
- `marketplace update` alone does neither job: it doesn't read `extraKnownMarketplaces` ("No
  marketplaces configured" on a fresh box) and doesn't move installed plugin code.
- **`claude-plugins-official` IS declared** in `extraKnownMarketplaces`: a fresh box doesn't have
  it registered, and every `@claude-plugins-official` install would fail.
- Every third-party marketplace has `"autoUpdate": true`; the official one auto-updates by default.
- Id lists render from the template via `includeTemplate … | fromJson` (single source); the
  rendered ids are part 2's run_onchange fingerprint.
- **`false` in `enabledPlugins` = installed but OFF** (both loops ignore the value). To remove a
  plugin, delete its line AND `claude plugin uninstall` it. Opt-in plugins `ecc@ecc`,
  `cloudflare@cloudflare`: enable per project with `claude plugin enable <id> --scope local`.
  ECC's rules aren't in the plugin — copy only what a project needs:
  `cp -r ~/.claude/plugins/cache/ecc/ecc/*/rules/{common,<lang>} .claude/rules/ecc/`
  (never globally: ~4.4k tokens per session).
- **claude-mem is fully plugin-managed**: its own Setup hook installs its runtime; data lives in
  `~/.claude-mem/`. **NEVER `npx claude-mem install`** (double-registers hooks; hook-enforced).

## Skills
- Overlapping skills: keep the standard/official one (no `document-skills`; the claude.ai-synced
  `anthropic-skills:*` cover it).
- Repos with no marketplace are `repo:skillspec:anchor` triples in part 2:
  `tt-a1i/archify:archify:archify`, `mattpocock/skills:*:ask-matt`.
  - `skillspec` = the `--skill` value (`*` tracks upstream; pinned names rot).
  - `anchor` = the `~/.claude/skills/<dir>` whose presence means "done"; `rm -rf` it to reinstall.
- `npx -y skills add <repo> --skill <spec> --agent claude-code -g -y --copy` — every flag is
  load-bearing: two different prompts need `npx -y` and `-y`; **without `--agent claude-code`
  Claude never sees the skill**; `--copy` because Windows symlinks need elevation.
- npx is mise's node, so skills are part of the **`develop` profile** (template-gated in both
  part 2s); on Unix the step tries PATH → `mise exec` → warn, on Windows a failure fails part 2.
  `~/.claude/skills/` is not chezmoi-managed.
- `skillOverrides` turns off unused `mattpocock/skills` entries. A repo whose skills would ALL be
  off is dropped instead (humanizer, find-skills, taste-skill; part 2 has a one-shot
  `skills remove` for them).
- `czu` runs one `npx -y skills update -g -y`. Remove a skill with `skills remove -g`, never `rm`
  — the lock (`~/.agents/.skill-lock.json`) would make `update` restore it.

## Statusline
- Windows uses `dot_claude/statusline.ps1` (one hidden `pwsh.exe`); Unix uses
  `executable_statusline.sh`. Git Bash on Windows flashes a console on every render (MSYS
  `AllocConsole` bypasses `windowsHide`). **Keep the two in sync**; each is OS-gated in
  `.chezmoiignore`.
