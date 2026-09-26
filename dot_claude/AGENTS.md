# AGENTS.md — Claude Code (dot_claude/ + the Claude parts of the bootstraps)

Scoped notes for `dot_claude/` and the Claude sections of `run_onchange_after_20-install-claude.*` / `run_after_update-claude-plugins.*`. Repo-wide rules live in the root `AGENTS.md`.

## Install, plugins, skills (bootstrap)
- **Claude Code itself is installed by the bootstrap**, using the documented "Native Install
  (Recommended)" one-liners VERBATIM — `irm https://claude.ai/install.ps1 | iex` on Windows,
  `curl -fsSL https://claude.ai/install.sh | bash` on Unix — only when `claude` is missing. It
  lands in `~/.local/bin` (already on PATH from the top of both scripts) and AUTO-UPDATES in the
  background afterwards. Do NOT swap in `winget install Anthropic.ClaudeCode` / `brew install
  --cask claude-code` / `npm i -g @anthropic-ai/claude-code`: per the docs those do NOT
  auto-update, so the box would silently drift behind. This is NOT optional polish: the
  marketplace/plugin step below is guarded on `claude` existing, so on a fresh box it would be a
  silent no-op AND would never retry, because the run_onchange fingerprint doesn't change
  afterwards. On Windows the install runs inside
  `& { … }` — the upstream installer sets `Set-StrictMode -Version Latest` and
  `$ErrorActionPreference = 'Stop'`, and the block scope keeps those out of the rest of the
  bootstrap (verified: the outer preference is unchanged after the block returns).
- **Claude marketplaces + plugins: `cza` INSTALLS WHAT'S MISSING, `czu` UPDATES WHAT'S THERE.**
  Two scripts, deliberately split:
  - **Install (bootstrap, `run_onchange_after_20-install-claude.{sh,ps1}`)** — `marketplace add`
    for every `extraKnownMarketplaces` entry not in `claude plugin marketplace list --json`, then
    `claude plugin install -y` for every `enabledPlugins` id not in `claude plugin list --json`.
    Both `list`s are local reads, so a box that already has everything does ZERO network work.
    `-y` is mandatory — the install prompt has no TTY here and would hang the bootstrap.
  - **Update (`run_after_update-claude-plugins.{sh,ps1}`)** — `claude plugin marketplace update`
    plus `claude plugin update <id>` per declared plugin. It is an ALWAYS-run script whose very
    EXISTENCE is gated in `.chezmoiignore` on `{{ ne .chezmoi.command "update" }}`, so only
    `chezmoi update`/`czu` ever sees it: `cza` stays config-only and offline, and an always-run
    script never parks a permanent `R` in `chezmoi status`. (`CHEZMOI_COMMAND` is also set to
    `apply`/`update` at runtime — the ignore gate is used instead because it also kills the
    status noise.)
  - **The old single `claude plugin marketplace update` line did neither job** — measured with a
    throwaway `CLAUDE_CONFIG_DIR`, so re-measure the same way before "simplifying" this back:
    - It does NOT read `extraKnownMarketplaces`. On a fresh box it prints **"No marketplaces
      configured"** and exits — nothing is ever cloned, so every plugin install then fails with
      *"not found in marketplace … your local copy may be out of date"*. Only `marketplace add`
      registers a marketplace (and it writes the entry into settings.json itself).
    - It does NOT refresh plugin code either; it only `git pull`s the marketplace clones under
      `~/.claude/plugins/marketplaces/`. Installed plugin code lives in
      `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and moves only on `claude
      plugin update` (measured: `marketplace update` left claude-mem at 13.13.1; `plugin update`
      took it to 13.24.23). `plugin update` takes ONE plugin, is idempotent, exits 0 on
      "already latest".
  - **`claude-plugins-official` is declared in `extraKnownMarketplaces` even though it's the
    built-in one.** A fresh box does NOT have it registered (Claude Code adds it on first
    interactive use), so without the declaration the add loop skips it and all the
    `@claude-plugins-official` plugins fail to install. Declaring it costs nothing on an
    existing box (the presence check skips it) and keeps ONE loop instead of a hardcoded
    special case. Verified end to end against an empty `CLAUDE_CONFIG_DIR`: 5 marketplaces
    added, 17 plugins installed, zero failures; the second run is silent.
  - **Every third-party marketplace carries `"autoUpdate": true`** (what `/plugin` → marketplace →
    "Enable auto-update" writes), so Claude Code refreshes it and its plugins at startup between
    `czu` runs. `claude-plugins-official` has no key — the official marketplace auto-updates by
    default. Toggling it in `/plugin` edits the live file only; the merge keeps it there, but mirror it in
    the template to share it.
  - Both scripts render their id lists from `.chezmoitemplates/claude-settings.json` via
    `includeTemplate … | fromJson`, so that file stays the single source of truth and there is no
    duplicate list. The RENDERED ids are also the bootstrap's run_onchange fingerprint — it
    re-fires exactly when a marketplace/plugin is declared, not on unrelated settings churn (the
    old `# settings fingerprint … | sha256sum` comment is gone). Add one by editing
    `enabledPlugins`/`extraKnownMarketplaces`, then `cza`. Every call is `|| echo` / `try/catch`
    so a network blip or a not-yet-installed `claude` never aborts setup.
- **`false` in `enabledPlugins` = installed but OFF, not "not installed".** Both loops use
  `range $id, $_` and ignore the value, so a `false` plugin is still installed by `cza` and
  updated by `czu`. To get rid of a plugin, DELETE its line (and `claude plugin uninstall` it on
  existing boxes); `false` is for opt-in plugins. **Opt-in plugins: `ecc@ecc` (marketplace
  `affaan-m/ECC`) and `cloudflare@cloudflare`** (14 skills in every session's listing, used once):
  off globally, turned on per project with `claude plugin enable <id> --scope local` (writes that repo's gitignored `.claude/settings.local.json`; `--scope project`
  shares it via `.claude/settings.json`). Its rules are NOT part of the plugin, and once lived
  in `~/.claude/rules/ecc`, which loaded ~4.4k tokens into EVERY session. For a project that
  wants them, copy only the needed dirs from the plugin cache:
  `cp -r ~/.claude/plugins/cache/ecc/ecc/*/rules/{common,<lang>} .claude/rules/ecc/`.
- **No `model` key, on purpose.** Picking "Default" in `/model` DELETES the key rather than
  writing `"default"`, so a tracked `"model": "default"` drifts on every such pick. Absent = the
  account's default model; a `/model` pick of anything else persists until the next `cza`.
- **Overlapping skills: keep the standard/official one.** No `document-skills` plugin (duplicates
  the claude.ai-synced `anthropic-skills:*`, which are account-level and not managed here).
- `skillOverrides` turns off skills that `mattpocock/skills:*` installs but that are never used.
  A repo whose skills would ALL be off is dropped instead: humanizer, find-skills and
  `Leonxlnx/taste-skill` (all 15 off; `frontend-design` covers UI work) were retired, and
  bootstrap part 2 runs a one-shot `skills remove` for them on boxes that still have them.
- **`claude-mem` (`thedotmack` marketplace) is fully plugin-managed — beyond the generic
  `claude plugin install` above, the bootstrap needs NO claude-mem step.** Its own plugin `Setup` hook (`version-check.js`) version-checks and
  installs/updates the runtime per session, and its data lives in `~/.claude-mem/` (SQLite DB +
  chroma vectors + `settings.json`/`.env`), which `cza` never touches. So the whole integration
  is just the `enabledPlugins` toggle + the `thedotmack` entry in `extraKnownMarketplaces`; the
  `czu` update script bumps the plugin code in place — it never reinstalls or wipes the local
  memory DB. Do NOT add `npx claude-mem install` to the bootstrap: that's the non-plugin install
  path and would double-register hooks against the plugin's own.
- **Agent skills from repos with no marketplace** are `repo:skillspec:anchor` triples in bootstrap
  part 2: `tt-a1i/archify:archify:archify`, `mattpocock/skills:*:ask-matt`.
  - **skillspec** = the `--skill` value; `*` = every skill the repo ships (tracks upstream; a
    pinned name list rots and fails on removed names).
  - **anchor** = the `~/.claude/skills/<dir>` whose presence means "done on this box" (a
    representative skill for a `*` entry). `rm -rf` it to force a reinstall.
  - Installed with `npx -y skills add <repo> --skill <spec> --agent claude-code -g -y --copy`.
    Every flag is load-bearing: `npx -y` and the trailing `-y` skip two DIFFERENT prompts;
    **`--agent claude-code` is required** (without it the CLI installs for codex/gemini/copilot
    and Claude never sees the skill); `--copy` because Windows symlinks need elevation.
  - `npx` is mise's node (`develop` profile), so the step is guarded (PATH → `mise exec` → warn)
    rather than template-gated. `~/.claude/skills/` is NOT chezmoi-managed.
  - `czu` refreshes them with one `npx -y skills update -g -y` (all global skills). To remove a
    skill use `skills remove -g`, not `rm`: the CLI's lock (`~/.agents/.skill-lock.json`) would
    otherwise make `skills update` restore it.

## Gotchas
- **Statusline: Git Bash flashes a console window on Windows; use the PowerShell port.**
  Claude relaunches the statusLine `command` as a native child on every UI update (verified: the
  spawned process has MSYS `PPID=1`, parented by node, not an outer `bash -c`). MSYS/Cygwin
  `bash.exe` calls `AllocConsole()` when its stdio is piped, BYPASSING Node's `windowsHide` — so
  Git Bash and its `jq`/`awk`/`tail` children flash a console each render, while native console
  apps (pwsh, node, git) spawned the same way stay hidden. Fix: `dot_claude/statusline.ps1`, so
  Windows launches ONE hidden `pwsh.exe`. `dot_claude/executable_statusline.sh` stays the
  macOS/Linux version; **keep the two in sync.** Both are OS-gated in `.chezmoiignore` (`.sh`
  ignored on Windows, `.ps1` on Unix), and `claude-settings.json` branches `statusLine.command`
  per-OS — a plain settings.json can't (one hardcoded command is always wrong on one OS: the
  clean-install-Windows bug). Bonus: the bash script's `echo -e` mangles Windows backslash paths
  (`\0` in `C:\Users\0x130` → NUL), so line 1 was already broken there.
- **`~/.claude/settings.json` is MERGED, not replaced: `dot_claude/modify_settings.json`**
  (a `chezmoi:modify-template`) reads the live file on stdin and merges in the curated keys from
  `.chezmoitemplates/claude-settings.json` (the source of truth; a template only so
  `statusLine` can branch per-OS). Rules: object keys merge one level deep with the curated
  entry winning (`enabledPlugins`, `extraKnownMarketplaces`, `env`, …); `permissions.allow` is a
  union; `hooks` and scalars are replaced; keys only the live file has are KEPT.
  - So machine-local edits (ad-hoc approved commands, a new plugin toggled in `/plugin`) survive
    `cza`, and a curated value that Claude overwrote (e.g. a marketplace's `autoUpdate`) comes back.
  - Consequence: deleting a curated entry does NOT delete it live — remove it by hand too (for a
    plugin, `claude plugin uninstall`). To share a live change, copy it into the template.
  - Output is `toPrettyJson` (sorted keys). The first apply after Claude reorders keys shows `M`;
    content is what `chezmoi verify` compares. Do NOT switch to symlink mode: Claude saves
    atomically via rename, replacing any symlink.
- **`~/.claude/CLAUDE.md` is managed (`dot_claude/CLAUDE.md`, plain file).** It keeps the
  `@RTK.md` import line that `rtk init -g` would otherwise add (so rtk's run finds it present)
  plus the global codegraph rule: `codegraph init --yes` in any source-code git repo without
  `.codegraph/`, then `codegraph_explore` before Grep/Read. `RTK.md` stays rtk-written and
  machine-local.
