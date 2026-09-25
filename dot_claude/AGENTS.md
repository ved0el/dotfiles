# AGENTS.md — Claude Code (dot_claude/ + the Claude parts of the bootstraps)

Scoped notes for `dot_claude/` and the Claude sections of `run_onchange_after_install-packages.*` / `run_after_update-claude-plugins.*`. Repo-wide rules live in the root `AGENTS.md`.

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
  - **Install (bootstrap, `run_onchange_after_install-packages.{sh,ps1}`)** — `marketplace add`
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
  - Both scripts render their id lists from `dot_claude/settings.json.tmpl` via
    `includeTemplate … | fromJson`, so that file stays the single source of truth and there is no
    duplicate list. The RENDERED ids are also the bootstrap's run_onchange fingerprint — it
    re-fires exactly when a marketplace/plugin is declared, not on unrelated settings churn (the
    old `# settings fingerprint … | sha256sum` comment is gone). Add one by editing
    `enabledPlugins`/`extraKnownMarketplaces`, then `cza`. Every call is `|| echo` / `try/catch`
    so a network blip or a not-yet-installed `claude` never aborts setup.
- **`false` in `enabledPlugins` = installed but OFF, not "not installed".** Both loops use
  `range $id, $_` and ignore the value, so a `false` plugin is still installed by `cza` and
  updated by `czu`. To get rid of a plugin, DELETE its line (and `claude plugin uninstall` it on
  existing boxes); `false` is for opt-in plugins. **`ecc@ecc` (marketplace `affaan-m/ECC`) is the
  one opt-in plugin:** off globally, turned on per project with `claude plugin enable ecc@ecc
  --scope local` (writes that repo's gitignored `.claude/settings.local.json`; `--scope project`
  shares it via `.claude/settings.json`). Its rules are NOT part of the plugin, and once lived
  in `~/.claude/rules/ecc`, which loaded ~4.4k tokens into EVERY session. For a project that
  wants them, copy only the needed dirs from the plugin cache:
  `cp -r ~/.claude/plugins/cache/ecc/ecc/*/rules/{common,<lang>} .claude/rules/ecc/`.
- `skillOverrides` (tracked) turns off skills that the `*` skill repos below install but that
  are never used. They stay on disk, and the skill listing no longer carries them.
- **`claude-mem` (`thedotmack` marketplace) is fully plugin-managed — beyond the generic
  `claude plugin install` above, the bootstrap needs NO claude-mem step.** Its own plugin `Setup` hook (`version-check.js`) version-checks and
  installs/updates the runtime per session, and its data lives in `~/.claude-mem/` (SQLite DB +
  chroma vectors + `settings.json`/`.env`), which `cza` never touches. So the whole integration
  is just the `enabledPlugins` toggle + the `thedotmack` entry in `extraKnownMarketplaces`; the
  `czu` update script bumps the plugin code in place — it never reinstalls or wipes the local
  memory DB. Do NOT add `npx claude-mem install` to the bootstrap: that's the non-plugin install
  path and would double-register hooks against the plugin's own.
- **Agent skills from repos with no marketplace** are declared as **`repo:skillspec:anchor`
  triples** — `blader/humanizer:humanizer:humanizer`, `tt-a1i/archify:archify:archify`,
  `vercel-labs/skills:find-skills:find-skills`, `mattpocock/skills:*:ask-matt`,
  `Leonxlnx/taste-skill:*:brandkit`. Each field earns its place:
  - **skillspec** = the `--skill` value. A literal name where only one skill is wanted — and it
    is NOT always the repo basename (`vercel-labs/skills` ships `find-skills`), so deriving it
    from the repo silently asks for a skill called "skills". `*` means "every skill this repo
    ships", which tracks upstream on its own: in three days `mattpocock/skills` went 38 → 37
    names and `Leonxlnx/taste-skill` 10 → 13, so a pinned name list would rot AND fail on the
    removed names.
  - **anchor** = the `~/.claude/skills/<dir>` whose presence means "this repo is already done on
    this box". Identical to skillspec for a single-skill entry; a representative skill for a `*`
    entry, because learning a `*` repo's real set costs the network round-trip the check exists
    to avoid. `rm -rf ~/.claude/skills/<anchor>` forces a reinstall.
  They are installed by both bootstraps with the `skills` CLI — `npx skills add <repo> -g`, the official
  method in each repo's own README. Humanizer ALSO offers a `/plugin marketplace add` path; it is
  deliberately NOT used, because archify has no marketplace at all, so the `skills` mechanism has
  to exist regardless — one mechanism for both beats splitting them, and it keeps
  `settings.json.tmpl` (and its fingerprint) untouched. Every flag is load-bearing for a
  non-interactive run and none may be dropped: `npx -y` skips **npx's own** "install skills?"
  prompt on a cold cache, the trailing `-y` skips the **CLI's** confirmation (two separate
  prompts, two separate flags), `--agent claude-code` suppresses the agent picker, `--skill`
  pins the selection, and `--copy` avoids symlinks — Windows symlinks need Developer Mode or
  elevation, which this bootstrap never takes. **`--agent claude-code` is the one that matters
  most**: without it the `skills` CLI installs for codex/gemini/copilot and Claude never sees the
  skill — this box had 50 skills in `~/.agents/skills` (per `~/.agents/.skill-lock.json`, the
  CLI's own record of what came from where) with only `archify` wired to Claude. That is the
  whole reason the two `*` repos are declared here.
  **`npx` comes from mise's `node = "lts"`, which lives in `develop.toml`** — so it is
  develop-gated even though Claude Code itself is base. Hence the rtk-style guard (`command -v
  npx` → `mise --cd "$HOME" exec --` → warn) rather than a `{{ if .develop }}` template gate: a
  tools-only box prints `[skills] … skipped` and carries on instead of silently shipping a
  script that can't run. Skills land in **`~/.claude/skills/<name>`, which chezmoi does NOT
  manage** (`chezmoi managed | grep -c '^.claude/skills'` → 0), so `apply` never fights them —
  and that dir IS the install check: the loop skips any triple whose anchor already exists, so
  `cza` never re-runs npx for a repo that's done (verified end to end: archify skipped,
  humanizer + find-skills + all of mattpocock/skills and taste-skill installed → 54 dirs in
  `~/.claude/skills`, second run silent, exit 0).
  Refreshing them is `czu`'s job — `run_after_update-claude-plugins.{sh,ps1}` runs a single
  `npx -y skills update -g -y`, which covers every GLOBAL skill (a superset of these three), so
  the repo:skill list is NOT duplicated there.

## Gotchas
- **Statusline: Git Bash flashes a console window on Windows; use the PowerShell port.**
  Claude relaunches the statusLine `command` as a native child on every UI update (verified: the
  spawned process has MSYS `PPID=1`, parented by node, not an outer `bash -c`). MSYS/Cygwin
  `bash.exe` calls `AllocConsole()` when its stdio is piped, BYPASSING Node's `windowsHide` — so
  Git Bash and its `jq`/`awk`/`tail` children flash a console each render, while native console
  apps (pwsh, node, git) spawned the same way stay hidden. Fix: `dot_claude/statusline.ps1`, so
  Windows launches ONE hidden `pwsh.exe`. `dot_claude/executable_statusline.sh` stays the
  macOS/Linux version; **keep the two in sync.** Both are OS-gated in `.chezmoiignore` (`.sh`
  ignored on Windows, `.ps1` on Unix), and `settings.json.tmpl` branches `statusLine.command`
  per-OS — a plain settings.json can't (one hardcoded command is always wrong on one OS: the
  clean-install-Windows bug). Bonus: the bash script's `echo -e` mangles Windows backslash paths
  (`\0` in `C:\Users\0x130` → NUL), so line 1 was already broken there.
- **`~/.claude/settings.json` is a fully-managed template (`dot_claude/settings.json.tmpl`) —
  chezmoi owns it, `apply` overwrites the live file.** It is a template ONLY so `statusLine` can
  branch per-OS; every other key is static. Tradeoffs, know them:
  - **`apply` CLOBBERS live machine-local keys.** Claude rewrites settings.json constantly
    (plugin toggles, marketplaces, ad-hoc approved commands) and those edits revert on the next
    `apply`. Because it's a `.tmpl`, `czra` does NOT round-trip (it would overwrite the `{{ }}`
    with literal JSON) — capture such a change by hand-editing the `enabledPlugins`/
    `extraKnownMarketplaces` blocks in the template, then commit.
  - Tracked = the curated shared state: `env` (`PONYTAIL_DEFAULT_MODE`), `defaultMode`, `hooks`
    (rtk), `statusLine` (per-OS), `permissions.allow` (Bash baseline + codegraph MCP),
    `enabledPlugins`, `extraKnownMarketplaces`, `skillOverrides`, `model` (`default` — `cza` undoes a persisted `/model` pick), UI prefs (`tui`, `timeFormat`, `editorMode`,
    `preferredNotifChannel`, `advisorModel`, the booleans).
  - Trips `chezmoi status`/`czd` and the `80-chezmoi-drift.zsh` nudge whenever Claude touches it
    — expected; `czd` to see what changed. Do NOT switch to symlink mode: Claude saves
    atomically via rename, replacing any symlink.
