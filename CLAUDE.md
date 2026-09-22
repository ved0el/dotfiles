# CLAUDE.md — dotfiles (chezmoi)

Personal dotfiles managed by [chezmoi](https://chezmoi.io). Files in this source
dir are applied to `$HOME`. Repo: `ved0el/dotfiles`.

## Commands

**Edit files HERE (the source dir) — `apply` overwrites `$HOME`.** `czra` captures a `$HOME`
edit after the fact, except on `.tmpl` targets (it writes literal JSON over the `{{ }}`).
Aliases ship in `dot_config/zsh/conf.d/70-aliases.zsh` (zsh) and
`dot_config/powershell/profile.ps1` (pwsh); both self-gate on `chezmoi` existing.

| alias  | command           | use |
|--------|-------------------|-----|
| `cz`   | `chezmoi`         | bare passthrough |
| `cza`  | `chezmoi apply`   | source → `$HOME`; re-runs the bootstrap if its fingerprint changed (installs missing Claude plugins, never updates existing ones) |
| `czd`  | `chezmoi diff`    | what `apply` would change |
| `czs`  | `chezmoi status`  | short per-file status (`R` = a script will run) |
| `cze`  | `chezmoi edit`    | edit a managed file in `$EDITOR` |
| `czra` | `chezmoi re-add`  | capture a `$HOME` edit back into the source repo |
| `czu`  | `chezmoi update`  | git pull, then apply; also the ONLY command that updates Claude plugins |
| `czcd` | `chezmoi cd`      | cd into this repo (to commit/push) |

Verify before apply:
- `chezmoi execute-template '{{ .tools }}|{{ .develop }}|{{ .tmux }}|{{ .wm }}'` — resolved profile data.
- `chezmoi cat-config` — the per-machine config that wins.
- `chezmoi apply -n -v` — dry-run diff. NOTE: the bootstrap script's text (e.g. `skhd`) shows in
  the diff; grep config paths like `^diff --git a/.config/...` to judge actual file application.
- `chezmoi managed | grep X` / `chezmoi ignored` — confirm what applies vs is excluded.

## Layout & naming
- `dot_X` → `~/.X`; `executable_X` → +x; `private_X` → 0600; `*.tmpl` → Go-templated.
- **Non-`dot_` files (README.md, CLAUDE.md) apply to `~/` unless in `.chezmoiignore`.**
- `run_after_update-claude-plugins.{sh,ps1}.tmpl` — refreshes Claude marketplaces/plugins;
  `.chezmoiignore` hides it from every command except `chezmoi update`.
- `run_onchange_after_install-packages.{sh,ps1}.tmpl` — bootstrap (packages + plugins);
  re-runs when its rendered content changes; `after_` = runs once files are applied.

| path | holds |
|------|-------|
| `dot_config/{bat,fd,ripgrep,micro,git,vivid}` | CLI tool configs (`tools` profile) |
| `dot_config/zsh/conf.d/*.zsh`, `dot_config/sheldon`, `dot_zshrc`, `dot_p10k.zsh` | Unix shell (numbered load order) |
| `dot_config/powershell/profile.ps1`, `dot_config/starship.toml` | Windows shell |
| `dot_config/mise/conf.d/*.toml` | tool/runtime manifests (all OSes) |
| `dot_config/{yabai,skhd}` / `dot_config/{komorebi,whkd,yasb}` | tiling WM: macOS / Windows |
| `dot_claude/` | Claude Code `settings.json.tmpl` + both statuslines |
| `dot_local/bin/` | tmux helper scripts (Unix only) |
| `dot_tmux.conf` | tmux (`tmux` profile) |

## What applies where

### Profiles (per-machine toggles — prompted)
- Data keys: `tools`, `develop`, `tmux` (Unix only), `wm` (macOS + Windows).
- Chosen by `chezmoi init` prompts in `.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`
  (overrides the `.chezmoidata.yaml` defaults). Re-run `chezmoi init` to change them;
  `apply` does NOT re-prompt.
- `.chezmoiignore` gates which files apply; the bootstrap gates installs by the same keys.
- Templates reference `.tools/.develop/.tmux/.wm` — they MUST exist or rendering errors
  ("map has no entry for key …"). `.chezmoidata.yaml` guarantees they exist.
- `tmux` is prompted only on non-Windows (forced `false` on Windows). `wm` is prompted on
  macOS (yabai + skhd) and Windows (komorebi + whkd + yasb); forced `false` on Linux.

### OS gate (NOT a prompt — auto-detected via `.chezmoi.os`)
- Three values: `windows` / `darwin` / `linux`. Never prompt for the OS; branch on it.
- **Bootstrap is split by OS family, one script each:**
  - `run_onchange_after_install-packages.sh.tmpl` — macOS (brew) + Linux (apt).
  - `run_onchange_after_install-packages.ps1.tmpl` — Windows (scoop).
  - `.chezmoiignore` ships exactly one (ignores `install-packages.ps1` on Unix and
    `install-packages.sh` on Windows — script target names drop the `run_*`/`.tmpl`).
    A `.sh` on Windows is unrunnable ("%1 is not a valid Win32 application"), so it MUST
    be ignored, not just rendered empty (the shebang line keeps it non-empty).
- chezmoi runs `.ps1` via `[interpreters.ps1]` (set Windows-only in `.chezmoi.toml.tmpl`):
  `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass` — **always WinPS 5.1** at its fixed
  `%SystemRoot%\System32\...` path, never pwsh. 5.1 is guaranteed on a fresh box and never moves;
  the bootstrap is written to run under it (then installs pwsh 7, from winget, for shells).
- **NEVER bake an absolute pwsh path into `.chezmoi.toml.tmpl`** (neither `[interpreters.ps1]` nor
  `[cd]`). pwsh's location depends on the install source and CHANGES under you — scoop
  (`<scoop>\apps\pwsh\current`) → winget/Store (a versioned `WindowsApps\Microsoft.PowerShell_X.Y.Z…`
  dir). A path baked at `chezmoi init` goes stale the moment pwsh moves: `chezmoi apply` then fails
  to run `.ps1` scripts, and `chezmoi cd`/`czcd` can't open a shell. `[interpreters.ps1]` uses the
  stable 5.1 path; `[cd]` uses **bare `pwsh`** so chezmoi resolves it via PATH at runtime (survives
  any pwsh source change with no re-init). (`lookPath "pwsh"` in the template has the same
  bake-at-init trap — don't use it for pwsh.)

## Tools split
- CLI tools + language runtimes → **mise** (`dot_config/mise/conf.d/{tools.toml.tmpl,develop.toml}`),
  cross-platform (macOS/Ubuntu/Raspberry Pi — one list, no per-OS name gaps). `tools.toml` is a
  template only to OS-gate `eza` (see the prebuilt-backend note below).
- `conf.d/windows.toml` — Windows-only mise tools (starship, the aqua `eza`; gated off in
  `.chezmoiignore` on Unix).
- Base via **OS PM** (brew/apt), installed only if missing: `git`, `curl`, `tmux`; Linux also
  gets `zsh` (this repo ships the whole zsh stack, and Debian/Ubuntu don't preinstall it — macOS
  does); macOS adds `mole` (cleanup CLI) and `yabai`/`skhd` (wm). No more `btop`/`tree`/`wget` —
  `btop`→`bottom` (mise) and `tree`→`eza -T` alias. `chsh` is NEVER run (it prompts for a
  password, which would hang a non-interactive bootstrap) — the script just prints the command.
- Windows base → **scoop** (`git mise openssh openssl JetBrainsMono-NF-Mono`) + **winget**
  (`Microsoft.PowerShell`) in the `.ps1` bootstrap. Each is guarded on the COMMAND
  (`Get-Command ssh`/`openssl` — a Git-for-Windows or optional-feature `ssh` already counts), so
  nothing reinstalls. The Nerd Font is the exception: a font ships no command, so it is guarded on
  `scoop list` instead, and it needs the `nerd-fonts` bucket added first. Fonts install per-user
  (HKCU), no elevation.
- **The archive extractor is NOT managed here.** NanaZip is installed by hand via winget
  (`M2Team.NanaZip`), which puts a `7z` app-alias on PATH. An earlier revision made the
  bootstrap `scoop install nanazip`, shim `7z` to its console exe and set `scoop config
  use_external_7zip true` — all removed. Do NOT re-add any of it; scoop pulling its own
  `7zip` package as a decompress dependency is expected and fine. (`use_external_7zip` may
  still be `True` in a machine's scoop config from that era — harmless, machine-local.)
- Prefer prebuilt backends where the registry default builds from source: `eza` is bare on
  macOS/Linux but `"aqua:eza-community/eza"` on Windows (registry default is `cargo:eza` — no
  Windows binary), hence the `{{ if ne .chezmoi.os "windows" }}` gate in `tools.toml.tmpl`.
  Same reason `micro`/`starship` use `aqua:` and `rtk`/`vivid` use `github:`. The backend
  prefix goes in the KEY, never the version value.
- **`rtk` (rtk-ai/rtk)** — `github:rtk-ai/rtk` (prebuilt release binary; the older `ubi:` backend
  works but mise deprecated it). The bootstrap also runs `rtk init -g --auto-patch` to register
  rtk's Claude Code command-rewrite hook globally. `--auto-patch` is REQUIRED: it patches
  `~/.claude/settings.json` without prompting, so the non-interactive bootstrap doesn't hang.
  Idempotent ("hook already present" on re-run); writes machine-local `~/.claude/RTK.md`. The rtk
  PreToolUse hook also ships in the managed `dot_claude/settings.json`, so the run finds it already
  present — `--auto-patch` mainly handles RTK.md + acts as a safety net.
- **`vivid` generates `LS_COLORS`** (mise `github:` backend). Its theme is the full upstream
  catppuccin-mocha with `red`→repo accent `#ff5189` (`dot_config/vivid/themes/
  catppuccin-mocha-red.yml`) — vivid needs a COMPLETE theme, a minimal override errors. zsh
  (`75-tools.zsh`) caches `vivid generate` to `$ZSH_CACHE_DIR/ls_colors` (regenerated when the
  theme changes) and feeds it to completion via `list-colors` (read at completion time, so it
  works despite running after compinit).
- **`delta` is wired into git via an include, NOT a managed `~/.gitconfig`.** Config lives in
  tracked `dot_config/git/delta.gitconfig`; the bootstrap adds an idempotent `include.path` to the
  UNMANAGED `~/.gitconfig` (identity/signing stay machine-local), gated `{{ if .tools }}`.
  `git config --global X` won't show included values without `--includes`, but real `git
  diff`/`log` follow the include fine. Both vivid + delta configs are `tools`-gated in
  `.chezmoiignore` (`.config/vivid`, `.config/git`).
- Completion uses fzf-tab (sheldon plugin, deferred) — it REQUIRES
  `zstyle ':completion:*' menu no` (never `menu select`); its `:fzf-tab:*` zstyles + eza/bat
  previews live in `50-completions.zsh` and inherit the catppuccin `FZF_DEFAULT_OPTS` via
  `use-fzf-default-opts`.
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
    interactive use), so without the declaration the add loop skips it and all 13
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

## Windows

### Shell & env
- **Package managers**: **scoop** (per-user, never elevated) installs `git` + `mise`; **winget**
  installs `Microsoft.PowerShell`. CLI tools come from **mise** (same `conf.d/*.toml` as Unix).
- **pwsh 7 comes from winget, NOT scoop.** The `winget` source ships `Microsoft.PowerShell` as an
  **MSIX bundle**, so it installs per-user with NO elevation (the MSI would need admin and would
  hang a non-interactive bootstrap) and drops a `pwsh.exe` app alias into
  `%LOCALAPPDATA%\Microsoft\WindowsApps`, on the user PATH by default. PATH resolution is the
  whole point: `[cd]` (`chezmoi cd`/`czcd`) and Claude Code's `statusLine` both invoke bare
  `pwsh`, so a box without it loses both. Flags are non-negotiable for a non-interactive run:
  `--accept-package-agreements --accept-source-agreements --disable-interactivity --silent`.
  Guarded by `Get-Command winget` (absent on LTSC/older builds) and by `$LASTEXITCODE`, so a
  failure warns instead of aborting. Any already-installed pwsh satisfies the `Get-Command pwsh`
  guard — the bootstrap never replaces one. The migration off scoop is proof the no-baked-path
  rule works: pwsh moved to `C:\Program Files\WindowsApps\Microsoft.PowerShell_<ver>_x64__…\`
  and `czcd` + the statusline kept working with no `chezmoi init` re-run.
- **The bootstrap resets `PSModulePath` on its first line.** It runs under WinPS 5.1 but
  inherits `PSModulePath` from whatever launched chezmoi. From pwsh 7 that list starts with
  pwsh's own module dirs, so 5.1 autoloads pwsh 7's `Microsoft.PowerShell.Security` and dies
  at the first cmdlet from it (`Get-ExecutionPolicy … module could not be loaded`, inside the
  scoop installer). It only bites when pwsh's `$PSHOME` is READABLE by 5.1. An MSI install
  (`Program Files\PowerShell\7`, as on GitHub's runners) is readable. A Store/winget install
  (`WindowsApps`) is ACL-hidden, so 5.1 silently skips it, which is why this box never saw the
  bug while `e2e-windows` failed on it every run. Reproduced locally by copying that module
  into a readable dir at the front of `PSModulePath`. The fix sets the list to 5.1's own:
  `Documents\WindowsPowerShell\Modules` plus the Machine-scope value.
- **A PowerShell module the profile needs must be installed THROUGH `pwsh`, not by the
  bootstrap process.** Each edition has its own CurrentUser module dir and neither sees the
  other's: pwsh 7's `PSModulePath` holds `~\Documents\PowerShell\Modules` and the machine-wide
  `Program Files\WindowsPowerShell\Modules`, but NOT `~\Documents\WindowsPowerShell\Modules`.
  The bootstrap runs under WinPS 5.1 (`[interpreters.ps1]`), so a bare `Install-Module` there
  lands where the profile's shell can never load it — and a bare `Get-Module -ListAvailable`
  guard is blind for the same reason, so it would reinstall on every run. Hence **PSFzf** is
  installed as `pwsh -NoProfile -Command '...Install-PSResource PSFzf -Scope CurrentUser
  -TrustRepository'` — guard and install both inside pwsh. `-TrustRepository` is the
  non-interactive flag (PSGallery is untrusted by default and would prompt);
  `Install-PSResource` ships with pwsh 7.4+.
- **The profile is dot-sourced from BOTH `$PROFILE`s, so gate anything newer than PSReadLine
  2.0.0.** pwsh 7.6 ships 2.4.5, WinPS 5.1 ships **2.0.0**, which has no `-PredictionSource` —
  ungated it throws on every 5.1 launch. (A box may have a newer one side-installed under
  `~\Documents\WindowsPowerShell\Modules` — this one does — so testing on it proves nothing
  about a fresh box; keep the gate.) The call is wrapped in `try/catch` (**not** `-ErrorAction SilentlyContinue`, which does not suppress it — the failure is terminating):
  PSReadLine refuses PredictionSource outright when console output is redirected or lacks VT
  processing, and a cosmetic feature must not paint the profile red. The block guards on `if ($psrl = Get-Module
  PSReadLine)` rather than `Import-Module`: the console host loads PSReadLine before `$PROFILE`
  runs, so testing for it LOADED also skips the block in a non-interactive host (`pwsh -Command`
  with piped stdin — Claude Code's tool shell), where there is no line editor to configure.
  `-PredictionViewStyle InlineView` is the DEFAULT — don't write it; `ListView` is the change.
  Tab is `Complete` (bash-style common prefix) over the default `TabCompleteNext` — but only
  as the FALLBACK: the PSFzf block rebinds Tab to `Invoke-FzfTabCompletion`. Order matters:
  the PSReadLine block runs first, so the later fzf bind wins whenever PSFzf loads.
- **PSFzf's chords live inside the `fzf` guard**, not a block of their own — they are useless
  without the binary. `Ctrl+t` provider, `Ctrl+r` history, `Alt+c` set-location, and `Tab`
  → `Invoke-FzfTabCompletion` (fzf over PowerShell's own completion results); `Ctrl+t`/`Ctrl+r`
  override PSReadLine's own `SwapCharacters` / `ReverseSearchHistory`.
- **PSFzf is LAZY-loaded: the profile never imports it.** `Import-Module PSFzf` costs ~150ms
  (a third of the old profile), so the four keys are bound to small scriptblocks that call
  `Use-PSFzf` (import once with `-Global`, apply `Set-PsFzfOption`, return `$true`) and then
  PSFzf's own exported handler (`Invoke-FzfTabCompletion`,
  `Invoke-FzfPsReadlineHandler{History,Provider,SetLocation}`). The first keypress pays the
  import once. If the import fails, `Tab`/`Ctrl+r` fall back to PSReadLine's `Complete` /
  `ReverseSearchHistory`. This also dropped `Get-Module -ListAvailable PSFzf` (~25ms, it scans
  every module dir). A bare import binds `Ctrl+t`/`Alt+c` to the same handlers itself, so that
  does not conflict.
- **PSFzf's Tab-completion preview is hidden (`-TabCompletionPreviewWindow 'hidden|hidden'`)
  because it is broken upstream (2.7.12, also on `master`), twice over:** (1) its lines are
  `CompletionText\0ListItemText` with `--delimiter '\0'`, and the preview passes `{}` = the
  WHOLE line, NUL included, which Go's exec rejects → `cmd.exe: invalid argument` in the
  preview pane; `{1}`/`{2}` would work (fzf strips the delimiter from fields). (2)
  `$script:PowershellCmd` is only assigned on WinPS 5.1, so on pwsh 7 the preview command has
  no program at all. Both measured in a real console by binding
  `load:execute-silent(<cmd> > file)+abort` — use `load`, not `start`: at `start` there is no
  item yet and fzf silently skips any command containing a placeholder, which fakes a
  failure. `hidden|hidden` also pins `ctrl-/` so the pane can't be toggled back into the
  error. `Ctrl+t` keeps its own bat preview (`FZF_CTRL_T_OPTS`) and is unaffected.
- **PowerShell profile**: managed at `dot_config/powershell/profile.ps1`
  (→ `~/.config/powershell/profile.ps1`). The bootstrap dot-sources it from the real
  `$PROFILE` (both pwsh 7 and WinPS 5.1 paths, via OneDrive-aware `GetFolderPath`).
  Edit the managed file, not `$PROFILE`.
- **Profile load time has a hard 500ms budget.** Above 500ms pwsh prints `Loading personal and
  system profiles took NNNms.` to stderr (`ConsoleHost.cs`, whenever the banner shows). It is
  a warning, not an error, but users read it as one, and because load time jitters it shows up
  only SOMETIMES. The profile sat at a 448-457ms median (measured before AND after the
  PSReadLine/PSFzf work, so that work was not the cause). It is now **~210ms**:

  | block | before | after | how |
  |---|---|---|---|
  | PSFzf import | 136-154 | 3 | lazy, see above |
  | starship | 87 | 34 | cached init; continuation prompt baked in |
  | gh completion | 58 | 21 | cached init |
  | zoxide | 25-39 | 16 | cached init |
  | mise env | 87 | 90 | **left alone**, see below |

  - **Cached init scripts:** `Get-InitScript` writes each tool's generated init once to
    `~/.cache/pwsh` (not chezmoi-managed) and the profile dot-sources the file. **The cache
    file is named after the exe's full path.** mise install paths embed the version
    (`…\installs\zoxide\0.10.0\zoxide.exe`), so an upgrade gives a new path and a fresh cache,
    with no invalidation logic. The file is written to a temp name and then renamed, so two
    windows opening at once never read a half-written file. It is written as UTF-8 **with**
    BOM because WinPS 5.1 also loads it. `rm -r ~/.cache/pwsh` forces a rebuild. Old caches
    are never pruned: every tool upgrade and every `starship.toml` edit leaves one ~10KB file
    behind.
  - **starship spawns TWICE per init, plus once more at load.** `starship init powershell` only
    prints a one-liner that re-runs starship with `--print-full-init`, so the full script is
    cached directly. That full script ALSO runs `starship prompt --continuation` at load time
    (~60ms) just to set `ContinuationPrompt`. `-Transform` bakes that string into the cache
    once, and `-DependsOn starship.toml` adds the config's mtime to the key, so a config edit
    rebuilds it. If a future starship reshapes that call, the `-replace` matches nothing and
    the spawn simply stays. Nothing breaks.
  - **Do NOT cache `mise env`.** Its output is a PATH full of versioned install dirs. A stale
    cache would silently drop tools after a `mise` upgrade, and checking whether the cache is
    still valid needs a mise spawn anyway, which is the cost you were trying to avoid.
  - **Measure it properly:** `Start-Process pwsh -Wait -ArgumentList '-NoExit','-NoProfile',
    '-File',<harness>` opens a REAL console, where PSReadLine is loaded the way it is at an
    interactive start. Time a copy of the profile with a Stopwatch mark before each `# ──`
    header, run it about 8 times, and read the MEDIAN. A single run lies: one cold run here
    took 1838ms, with every block 3-8x slower at once. That is Defender/disk cache, and no
    profile change fixes it. `host start->profile` (~490ms) is .NET/pwsh startup, which
    happens before the profile and is outside this budget.
  - Removals use `-ErrorAction Ignore`, not `SilentlyContinue`. `SilentlyContinue` still
    records an entry in `$Error` on every launch.
- **`XDG_CONFIG_HOME=~/.config`** is persisted (user env) by the bootstrap + set in the
  profile so XDG-aware tools read `~/.config` (mise's config dir resolves to `~/.config/mise`).
  Exported on every platform — Unix sets it in `zsh/conf.d/10-env.zsh` — so configs live under
  `~/.config` identically everywhere. (Do NOT pair it with `MISE_GLOBAL_CONFIG_FILE`; see
  Gotchas → mise.)
- **`powershell.exe` (WinPS 5.1) "not recognized"** → its dir
  `%SystemRoot%\System32\WindowsPowerShell\v1.0` fell off PATH (a Windows default that a trimmed
  Machine PATH can drop), breaking whkd keybinds, `[interpreters.ps1]`, and komorebi autostart.
  **Fix**: add that dir to the User PATH. Not a bootstrap step — a fresh box has it by default;
  only a hand-mangled PATH loses it. (pwsh 7 is unaffected — this is WinPS 5.1 only.)
- **starship** (`dot_config/starship.toml`, Windows-gated like `.config/powershell`) sets
  `scan_timeout = 500`: it globs the CWD once per prompt to pick language modules, and a cold FS
  cache (+ Defender) blows the 30ms default → `[WARN] … Scanning current directory timed out`.
  It's a CEILING, not a cost (warm scan ≈1ms), so raising it slows nothing. Measure with
  `starship timings`, never by guessing. What it shows here:
  - ~5ms outside a git repo, **~100ms inside one** — ~70ms of that is FIXED git-repo-discovery
    cost, independent of repo size, billed to whichever git-aware module runs FIRST (`directory`
    via its default `truncate_to_repo`, else `git_branch`). That toggle MOVES the 70ms, it
    doesn't remove it; only a prompt with no git info at all drops it. Don't "optimize" it.
  - `git_status` (~30ms) is a real `git status` subprocess — the one genuinely cuttable chunk,
    but it's information you want. Left enabled.
  - `docker_context` disabled: 3ms of a ~5ms non-repo prompt, and it renders nothing unless
    you're on a non-default docker context.
- Skipped on Windows: tmux, sheldon, p10k, `.claude/statusline.sh` (Windows uses
  `.claude/statusline.ps1` instead — see Gotchas → Claude Code).

### Window manager (`wm` profile)
scoop installs `komorebi whkd yasb` (extras bucket); configs `dot_config/{whkd,komorebi,yasb}`
apply only on Windows+wm (gated like skhd/yabai).
- **Config homes**: `KOMOREBI_CONFIG_HOME`/`WHKD_CONFIG_HOME`/`YASB_CONFIG_HOME` → `~/.config/<tool>`,
  persisted at User scope by the bootstrap (these apps launch at startup, outside any shell
  profile; else komorebi defaults to `~/komorebi.json`, whkd to `~/.config/whkdrc`).
- **komorebi autostart = a logon scheduled task** named `komorebi`, NOT `komorebic
  enable-autostart` or a shell:startup shortcut. Why those fail: at login scoop's shims aren't
  on PATH, so `komorebic start` (which does `Start-Process komorebi.exe`) can't find
  komorebi.exe — nothing tiles (reproduce: strip `<scoop>\shims` from PATH). The task runs the
  managed launcher `dot_config/komorebi/autostart.ps1`, which resolves `-ShimsDir` at
  registration (`Split-Path (Get-Command komorebic).Source`, while PATH is intact — scoop can
  live anywhere, e.g. `D:\scoop`, and doesn't set `$env:SCOOP`), prepends it to PATH, then starts
  komorebi+whkd ASAP with retry (no up-front sleep), and runs `komorebic replace-configuration`
  once `komorebic state` succeeds — a readiness probe, not a fixed sleep. That reload only covers
  windows ALREADY OPEN at login; it does nothing for windows opened later (see the extension-popup
  gotcha below). Note the command is `replace-configuration` — `reload-configuration` is for the
  LEGACY `komorebi.ahk`/`.ps1` configs and is a silent no-op against a static `komorebi.json`.
- **Task command = `<System32 powershell.exe> -NoProfile -ExecutionPolicy Bypass -WindowStyle
  Hidden -File autostart.ps1 -ShimsDir <shims>`.** WinPS 5.1 because pwsh isn't reliably on the
  task PATH. `-WindowStyle Hidden` is sufficient — no console appears (verified by enumerating
  visible windows during a task run).
- **NEVER wrap the task command in `conhost.exe --headless`.** At LOGON it can't allocate its
  pseudoconsole during early session init: the task dies with `0x80070003` (ERROR_PATH_NOT_FOUND)
  and nothing tiles. The trap is that it works ON DEMAND — `Start-ScheduledTask` reports `0x0`
  while every real logon fails, so diagnose with `(Get-ScheduledTaskInfo -TaskName
  komorebi).LastTaskResult` right after a REBOOT. It was added to kill a console flash that
  actually came from `komorebic start` spawning pwsh; the launcher now starts `komorebi.exe`/
  `whkd.exe` directly, so no flash remains. Also do NOT revert to a VBScript/mshta launcher (both
  deprecated) or a shell:startup shortcut/`komorebi.vbs` (races the task — the bootstrap deletes `komorebi.lnk`).
- **yasb** autostarts via its own installer. Its `config.yaml.tmpl` templates user paths with
  `{{ .chezmoi.homeDir | replace "/" "\\" }}` — never hardcode the username.
- **Browser extension popups are titled `_crx_<extension-id>`, NOT the extension's name.** A
  popped-out Chromium extension window belongs to the BROWSER exe (`brave.exe`, class
  `Chrome_WidgetWin_1`) and its title is Chromium's internal id form — the Bitwarden popup is
  literally `_crx_nngceckbapebfimnlniiiahkandclblb`. So a `Title` rule for `"Bitwarden"` never
  matches, at any `matching_strategy`, and komorebi tiles the popup. The rule here is therefore
  `floating_applications` / `Title` / `StartsWith` / `_crx_` — ONE rule covering every popped-out
  extension from any Chromium browser, with no per-extension id to maintain. The title is final
  at window-creation time (no ` - Brave` suffix, no later rename), so this is not a title-timing
  problem and needs no reload to take effect.
  **Get the real identifiers from komorebi's own log, don't guess**: `%TEMP%\komorebi_plaintext.log*`
  logs every event as `(hwnd: N, title: …, exe: …, class: …)`. Grep it for the app; if the name
  never appears, that IS the finding. **Asymmetry when auditing rules with that log: FLOATED
  windows are still logged (`Picture in picture` shows up), but IGNORED ones are not logged at
  all.** So zero hits disproves a `floating_applications` rule, and proves nothing about an
  `ignore_rules` entry — never delete an ignore rule on log silence alone. Find an extension's id under
  `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extensions\` (its
  `_locales/en/messages.json` gives the display name) — only needed to narrow the rule to a
  SINGLE extension; the `_crx_` prefix rule needs no id at all.
- **Seelen UI conflict**: komorebi fights any concurrent tiling WM (`seelen-ui.exe`). Keep
  Seelen for its dock but turn OFF its window manager (this box has
  `@seelen/window-manager: enabled:false`), or neither tiles cleanly.

#### yasb bar: fonts, icons, sizing
One text font and one icon font, both declared in `dot_config/yasb/styles.css`; the icon
codepoints live in `dot_config/yasb/config.yaml.tmpl`. Run `yasbc reload` after any change here,
and read the two restart traps at the end before concluding something is broken.

- **The bar is glass, and that is a STYLESHEET setting, not a config one.** `Bar.__init__`
  already sets `WA_TranslucentBackground` and already calls `enable_blur()` whenever
  `blur_effect.enabled` is true, so the DWM blur was running all along - an opaque
  `background-color` was simply painted over it. `.yasb-bar` therefore takes
  `--crust-glass: rgba(17, 17, 27, 0.55)` over `--glass-edge` for the lit hairline; the alpha
  IS the effect. Do NOT reach for `blur_effect.acrylic` to get this: 2.0.7's `enable_blur()`
  takes no acrylic argument (it picks `ACCENT_ENABLE_BLURBEHIND` on build >= 22000,
  `ACCENT_ENABLE_ACRYLICBLURBEHIND` below), and upstream marks the key
  "no longer supported" - it is dead either way.
- **Write bar alpha as `rgba()`, NEVER as 8-digit hex.** `CSSProcessor` defines
  `_css_to_qt_hex_alpha` (`#RRGGBBAA` -> Qt's `#AARRGGBB`) but **`process()` never calls it** in
  2.0.7 - confirmed by reading `process`'s own name table. So `#11111b8c` reaches Qt raw, is
  read alpha-first, and silently renders as a ~7% blue instead of a 55% near-black. `rgba()`
  needs no preprocessing at all; Qt accepts it, `rgba(r,g,b,55%)` and `#AARRGGBB` identically.
  The popup menus (`.home-menu`, `.language-menu`, `.komorebi-layout-menu`) keep opaque
  `--crust` on purpose - they are separate windows with no blur behind them, so alpha there
  only reads as muddy.
- **Verify a stylesheet change by driving yasb's OWN `CSSProcessor`, not by eye.** Put
  `library.zip` on `sys.path` under **Python 3.14** (the bundled bytecode's magic; 3.13 fails
  with "bad magic number"), call `CSSProcessor(path).process()`, and assert on the resolved
  rule - that catches an unresolved `var()`, which Qt drops silently and which would leave the
  bar fully transparent. To check a rendered result, screenshot the real bar and measure it;
  `QWidget.render()` composites a frame more than once, so an alpha of 0.55 reads as ~0.8 there
  and absolute pixel values from it mean nothing.

- **Text = `Noto Sans JP`, icons = `JetBrainsMonoNL Nerd Font`, and the Nerd Font is also second
  in every text rule.** Noto is the only Google family installed here that covers everything the
  bar shows: Latin 95/95, **Vietnamese 90/90** (`U+1EA0`-`U+1EF9`), full Japanese (86 hiragana,
  91 katakana, 12,731 kanji). Be Vietnam Pro and Roboto match it on Vietnamese but have ZERO
  CJK; Hack has **6 of the 90** Vietnamese codepoints, so Vietnamese window titles switch font
  mid-word in it. Noto's digits are tabular (all advance 9.0) so the clock does not jitter -
  check that before swapping in any proportional font. Noto is NOT installed by the bootstrap
  (scoop has no plain Noto Sans JP), so a fresh box falls through to the Nerd Font and loses
  only Japanese.
- **Icons are a Nerd Font rather than a UI icon font because only a Nerd Font shares the text's
  line.** Ink band relative to the shared baseline (0 = sitting on it):

  | | ink bottom | ink top |
  |---|---|---|
  | text cap `M`/`8` | 0 | 11 |
  | text `x` | 0 | 8 |
  | Segoe Fluent Icons | 0 | **13-15** |
  | Nerd Font icons | **-1 ... -2** | **11-12** |

  Segoe fills its em box and sits ON the baseline, so it towers 3-5px over the cap line at any
  size (shrinking it to match means a 10px icon). Nerd Font icons are patched onto the text
  font's own metrics and straddle the text band instead. Qt offers no `vertical-align` or
  `line-height` lever on an inline `<span>`, so the font IS the fix. The price: the glyph inks
  ~6.6px past its 9px advance (see `min-width` below), and Segoe and Nerd Font define many of
  the SAME PUA codepoints with DIFFERENT artwork, so 36 of them had to be re-picked. Verify
  coverage by intersecting the config's PUA set with the face's `cmap` after any icon edit.
- **The family name is spelled differently per consumer, on purpose.** `styles.css` uses the
  typographic name `JetBrainsMonoNL Nerd Font` (Qt matches name **ID 16** only - `... NF`,
  `NFM`, `NFP`, `... Nerd Font Mono` all silently become **Tahoma**); `komorebi.bar.json` uses
  the Win32 name `JetBrainsMonoNL NF` (DirectWrite = **ID 1**).
  `System.Drawing.Text.InstalledFontCollection` lists ID 1 only, so it is the WRONG tool to
  check Qt with - ask Qt through yasb's bundled PyQt6, under the real platform plugin
  (`QT_QPA_PLATFORM=offscreen` reports an empty font DB). `komorebi-bar --fonts` prints the
  names komorebi can actually see.
- **Sizes are set by measured INK, never by `font-size`** - each glyph fills a different share
  of its em box. Reference: the text cap/digit at 14px inks **11px tall, band `(0, 11)`**.

  | rule | px | ink | why |
  |---|---|---|---|
  | `*` (text) | 14 | 11 | the reference |
  | `.icon, .btn` | 13 | ~11 | shared default; 15px made every icon overshoot the cap |
  | `.weather-widget .icon` | 17 | 12 | the cloud inks only 9 at 13px |
  | `.whkd-widget .icon` | 17 | 12 | keyboard, same |
  | `.media-widget .btn` | 18 | 12 | transport glyphs ink 8 at 13px |
  | `.systray .unpinned-visibility-btn` | 18 | 12 | chevrons, same |
  | `.pomodoro-widget .icon` | 15 | 13 | solid stopwatch `F13AB` |
  | `.notification-widget .icon` | 16 | 14 | solid bell `F009A`; outline+badge `EB9A` reads smaller at the same height |
  | `.language-widget .icon` | 14 | 12 | |
  | `.home-widget .icon` | 18 | 17 | control; thin radial glyph, needs +2 over layout to LOOK equal |
  | `.komorebi-active-layout .label` | 20 | 15 | control; `padding-right` IS the window title's left gap, `padding-bottom: 2px` is its centring |
  | `.power-menu-widget .icon` | 23 | 17 | control; `F0425` uniquely sits at band bottom 0 at EVERY size |

  The first four are normalisation for glyphs that are unusually small in their em box - not the
  per-widget drift that was swept out. Add a row only with a measured ink number beside it.
- **Align by ink band, measured, not by eye.** `ascent - bbox` for the text cap and for the
  candidate glyph; one pixel off reads as visibly floating (`F0EE0` at `(-1, 12)` beside a
  neighbour at `(0, 11)`). Check the band the same way you check the `cmap`.
- **Centre a glyph on the BAR, never on the icon next to it.** The bar body is rows `y 6..39`
  (fill `7..38` plus a 1px border each side, at `height: 34` + `padding.top: 6`), so its centre
  is **22.5**. The komorebi layout icon had always sat at 23.5-24.0; aligning the home icon to
  *it* made the pair agree with each other and stay visibly low in the bar, which is the bug a
  fresh pair of eyes reports. Measure the bar's own rows first - dump a pixel column at an x
  with no glyph and read where the fill starts and stops - then align every icon to that.
  A glyph with **even** ink lands on 22.5 exactly (bell 14, power 16); **odd** ink cannot, it
  can only reach 22.0 or 23.0, so 0.5px is the floor there, not a miss worth chasing.
- **Vertical padding moves ink by HALF what you write.** The padding grows the widget and the
  bar re-centres it, eating the other half: `padding-top: 2px` shifted the home glyph exactly
  1px, 4px shifted it 2px. Measure the 2px step before trusting the ratio on a new widget.
  Also note shrinking `font-size` does NOT shrink a glyph about its centre - 19px->17px took
  the home icon's band from `(15,31)` to `(15,29)`, i.e. it lost the 2px off the BOTTOM with
  the top pinned, so a size change and a centring change are two separate steps.
- **`min-width` lives on `.icon` alone, sized per widget to that icon's ink + 2.** A too-narrow
  icon QLabel clips the glyph's **LEFT** side, not its right: the wifi wedge inks 15px inside a
  9px advance and its label is right-aligned, so the overflow was cut off the leading edge.
  Symptom to recognise - a symmetric glyph rendering lopsided while the same codepoint is
  symmetric in a standalone render. The shared `18px` left 2px of slack behind a 16px-wide cloud
  but 6px behind a 12px glyph, and that 4px WAS the uneven icon-to-text gap; narrow icons carry
  `min-width: 14px`. Do NOT put it on `.icon, .btn` - `.btn` is the media transport with its own
  tight `padding: 0 2px`, and an 18px box spreads the three controls apart.
- **The icon-to-text gap is three pieces and every label must contribute all three**: the slack
  `min-width` leaves after the ink, `.icon`'s `padding-right: 4px`, and ONE space in the label
  template. That lands at 7-12px; the spread is the first text character's left side bearing
  (`9`/`s` tight, `6`/`1` roomy) and cannot be equalised. Labels that END at the span carry a
  trailing **U+00A0**, because an inline span ignores padding - `&nbsp;` does NOT work, yasb
  renders the literal text. Every icon-bearing `<span>` needs `class='icon'` or it finds the
  glyph by fallback and misses the box entirely. Grep for `<span>` without the class, and for
  `</span>{`, after any icon edit.
- **A glyph inside `<span class='icon'>` takes `.icon`'s `font-size` and `color`, NOT the
  widget's `.label` rule.** This cost four rounds on the power button: it was raised
  14 -> 17 -> 22 -> 29 on `.power-menu-widget .label` with no visible change at all, because the
  glyph was still reading `.icon`'s 13px. Style a widget's icon with `.<widget> .icon`; writing
  it on `.label` fails silently - same trap for `color`, the red had to be restated on `.icon`.
- **Raising an icon's base colour means raising its `:hover` too.** The home glyph ran
  `--overlay1` -> `--overlay2` on hover, i.e. dim -> less dim. Lifting the base to `--text` and
  leaving that pair would have made it go DARKER on hover; it is `--text` -> `#ffffff` now.
  Brightness also changes what "the same size" looks like: the +2 ink this glyph carries was
  calibrated while it was dim, and at full `--text` it briefly read oversized - the fix was
  centring, not shrinking, so re-measure before trusting a size complaint after a colour change.
- **cpu/memory/wifi/volume are the TEXT tags `C:` `R:` `W:` `V:`, not icons.** Every glyph in
  this font that sits in the text's ink band is some flavour of chip (`F061A`, `F035B`, `F0EE0`,
  `F0A0C` ...), so cpu and ram could never be told apart at bar size; the ones that ARE distinct
  (`F4BC`, `F2DB`) sit 2-3px out of band and float. A tag is unambiguous AND aligned by
  construction, because it is text. Do not "improve" this back into icons without first finding
  two in-band glyphs a stranger can name.
- **The icon set is Material (`nf-md-*`) throughout.** The rule is one STROKE WEIGHT, not one
  family - mixing is fine when the result stays coherent - but Material won every slot on
  comparison, including the komorebi layouts: its `view-*` block maps onto them exactly
  (`F056E` bsp, `F0576` columns, `F056A` rows, `F0570` grid, `F056B`/`F0575` stacks, `F056C`
  ultrawide, `F0574` right-main), and it is solid where Codicon was hairline. A Nerd Font is
  FIVE icon families in one file with different stroke weights: audit by rendering every
  codepoint at the real bar size next to a 3x blow-up - Codicon `EBxx` and Font Awesome
  `F0xx`/`F2xx` line art turns to mush at 13-15px. `font-weight` cannot help: the same icon
  rasterises byte-identically in Regular/Medium/SemiBold/Bold.
- **The frozen volume readout is a yasb BUG, not this config - do not try to fix it in
  config.** Verified 2026-09-16 on yasb **2.0.7** (latest; upstream `main`'s
  `src/core/widgets/services/volume/service.py` is byte-identical to the shipped bytecode, and
  no issue is open for it). Mechanism, read from `library.zip`:
  - `AudioOutputService.register_widget()` calls `_register_callbacks()` **once**, only when the
    FIRST volume widget registers. There is no retry and `VolumeConfig` has no `update_interval`
    - the readout is purely COM-callback driven.
  - Every failure path is `except Exception: pass` with **no log line**, so a dead callback
    leaves `yasb.log` completely clean. Do not go looking for an error there.
  - `_on_device_change()` assigns `self._volume_callback` BEFORE calling
    `RegisterControlChangeNotify()`. If that raises - which is exactly what a default endpoint
    disappearing mid-transition does - the attribute is left non-None while nothing is actually
    registered, and `_register_callbacks()`'s `not self._volume_callback` guard then skips it
    forever.
  - This box's default device is **Speakers (Realtek USB Audio)**; a USB endpoint drops out on
    dock/monitor sleep, so it hits that path routinely.
  - **`yasbc reload` does NOT re-register it; `yasbc stop` then `yasbc start` does** - that is
    what the `yasbr` function in `dot_config/powershell/profile.ps1` is for. Confirmed by
    driving the real endpoint with yasb's own bundled pycaw (`library.zip` + `lib` on
    `sys.path`; the loose `psutil._psutil_windows.pyd` must be preloaded by hand because psutil
    itself is zipimported): frozen at 42% while the system went 100% -> 30%, then tracking
    77% -> 25% after a restart. Synthetic `keybd_event` volume keys do NOT move the system
    volume and make a useless harness.
  - **The old "the volume label must be wrapped in a `<span>`" claim is WRONG** - `_update_label`
    splits on `(<span.*?>.*?</span>)` and calls `setText` on the plain-text branch too, so
    `V: {level}` updates fine when the callback is alive. The span only ever changed the timing
    of a restart.
- **Changing a label's STRUCTURE needs a reload, not just an apply.** yasb splits the label on
  `(<span...</span>)` and builds one QLabel per part at startup, so adding or removing a span
  while it is running leaves the old widget list in place and the value freezes.
- History: `b1d8ccf`..`aef0e66` is an earlier rework that was reverted wholesale; everything
  from `d09e58e` on is the current design. `git show` those before re-litigating any of it.

## Gotchas

### chezmoi
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link
  with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`, and `apply`
  does NOT re-prompt profiles — edit that config or re-run `init`.

### mise
- **NEVER set `MISE_GLOBAL_CONFIG_FILE`.** mise's default global config is already
  `~/.config/mise/config.toml`, so setting it is redundant — and it actively breaks `conf.d`:
  with it set, mise stops auto-discovering the global config DIRECTORY (the `conf.d/*.toml`
  tool manifests) whenever a shell's CWD is outside `$HOME` (e.g. a terminal whose start
  directory is a drive root). Symptom: `mise ls` shows tools with a blank config source —
  only `config.toml` is read. Proven by toggling the var from a dir outside `$HOME`. Leave it
  unset everywhere; `profile.ps1` and `10-env.zsh` `unset` both vars at shell start, so a shell
  that inherits a stale value heals. (The bootstrap no longer clears the persisted User-scope
  var — if a box has one, delete it by hand.) (`MISE_CONFIG_DIR` is likewise
  unnecessary. Don't reintroduce either var to "pin" conf.d; pinning is what caused the bug.)
- `.config/mise/config.toml` is in `.chezmoiignore` → chezmoi never manages it, and `mise use
  -g` writes there by DEFAULT (no env var needed), so ad-hoc per-machine pins survive `apply`.
  NEVER let `mise use -g` land in a tracked `conf.d/*.toml` (it makes `apply` prompt "changed
  since chezmoi last wrote it" and reverts the pin).
- mise only auto-discovers the global `conf.d/*.toml` when CWD is inside `$HOME`; the bootstraps
  therefore run `mise --cd $HOME install` so a fresh-machine install isn't blank when chezmoi
  runs the script from elsewhere. The PowerShell profile injects tools via `mise --cd $HOME env`,
  so tools work in every shell regardless of its start directory.
- **Two lessons this bug bought — they generalize:**
  1. **Setting an env var to a tool's OWN DEFAULT is not a harmless no-op.** A tool that
     auto-discovers config by walking a directory often narrows to single-file mode the moment
     you hand it an explicit path. If the value equals the default, DELETE it; guard/`unset`.
  2. **Reproduce context-sensitive bugs in the ACTUAL failing context; verify env fixes in a
     FRESH process tree.** This one only appeared with CWD outside `$HOME` — testing from the
     repo dir hid it and gave a wrong first diagnosis. A child shell inherits stale env, so a
     fix can look broken or look fixed purely from inheritance.

### Shell (zsh + pwsh)
- **PowerShell resolves ALIASES before FUNCTIONS.** A `function ls { eza … }` in the profile
  is silently shadowed by the shipped `ls`→Get-ChildItem alias (so `ls` keeps built-in output
  even though the function exists). The eza block therefore `Remove-Item Alias:ls -Force` before
  defining the function. Only `ls` collides with a built-in alias (la/ll/lt/lm/… don't; `tree`
  is an .exe, which a function already outranks). zsh is unaffected — it uses `alias ls=…`, not
  a function. If you add a new eza/tool function whose name is also a default PS alias, drop the
  alias too. (`Get-Command ls` showing `CommandType: Alias` instead of `Function` = the bug.)
- **zoxide must init AFTER starship in the PowerShell profile.** zoxide does NOT shadow `cd` —
  it records visited dirs via a hook that WRAPS the existing `prompt` function (capturing it
  once, guarded by `$__zoxide_hooked`). starship REPLACES `prompt` wholesale, so if zoxide inits
  first, starship clobbers the hook and NO directory is ever recorded → `z foo` says "not found"
  while the DB silently freezes (stale entries still resolve, new dirs never appear). Order:
  gh → starship → zoxide (zoxide last among prompt-touching inits). Symptom check:
  `(\$function:prompt) -match '__zoxide_hook'` must be True in a real shell; `zoxide query -l`
  missing a dir you just visited = the bug. TESTING TRAP: `pwsh -Command` already auto-loads the
  profile, so an extra `. $PROFILE` double-loads it and gives a FALSE NEGATIVE (starship replaces
  the prompt again; zoxide's once-only guard skips re-wrapping) — test in a single-load shell.
  (zsh is unaffected: `zoxide init zsh` uses a `chpwd`/`precmd` hook ARRAY, not a wrapped
  function, so order vs starship/p10k doesn't matter the same way.)
- **`cd` → zoxide is guarded by `CLAUDECODE` on BOTH shells.** The profile sets `Set-Alias cd
  __zoxide_z` (+ `cdi`→`__zoxide_zi`) to mirror zsh's `alias cd="z"`/`alias cdi="zi"`, so
  `cd <keyword>` fuzzy-jumps everywhere; `__zoxide_z` still cd's literally for real paths
  (`cd ..`, `cd C:\x`, `cd .\sub`). `-Force` is required to override the built-in read-only
  `cd`→Set-Location alias; `-Option AllScope` follows it into nested scopes. But inside Claude
  Code's tool shell (`CLAUDECODE=1`) a `cd <badpath>` would route through zoxide and leak
  `zoxide: no match found` into piped output, corrupting rtk's JSON rewrites and grep/JSON
  pipelines — so `[[ -z "$CLAUDECODE" ]]` / `-not $env:CLAUDECODE` keeps the real `cd` builtin
  there. (rtk's hook is NOT the culprit — it passes `cd` through untouched; the alias was.)

### Claude Code
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
    `enabledPlugins`, `extraKnownMarketplaces`, UI prefs (`tui`, `timeFormat`, `editorMode`,
    `preferredNotifChannel`, `advisorModel`, the booleans).
  - Trips `chezmoi status`/`czd` and the `80-chezmoi-drift.zsh` nudge whenever Claude touches it
    — expected; `czd` to see what changed. Do NOT switch to symlink mode: Claude saves
    atomically via rename, replacing any symlink.

### tmux (Unix)
- **Plugins install via `git clone` in the bootstrap — no tmux server.** Do NOT "fix" it to use
  TPM's `bin/install_plugins`: that needs a live server that has sourced the config (for
  `TMUX_PLUGIN_MANAGER_PATH`); during a non-interactive bootstrap a session-less
  `tmux start-server` exits first → TPM aborts "not configured" → 0 plugins, AND it leaves a
  stale server on the default socket → plain `tmux` then dies with "server exited unexpectedly"
  after the next tmux upgrade (old server vs new client). A "plugin install" is just a clone into
  `~/.tmux/plugins/<name>`, so the bootstrap parses `@plugin` lines and clones them. After
  upgrading tmux, `tmux kill-server` (or relog) to drop a stale old-version server.
- **Status-bar `#(…)` runs as the SERVER's user, not the pane's.** So the old
  `status-left … #(whoami)` froze on the login that started the server and never tracked
  `sudo -i`/`su -`. Fix: `~/.local/bin/tmux-user` (`executable_tmux-user`, tmux-only — ignored
  on Windows like `tmux-sessionizer`) takes `#{pane_tty}` and reports the owner of the tty's
  FOREGROUND process group (the first proc with `+` in STAT — works on BSD/macOS + GNU/Linux),
  so the bar switches to `root` the moment you elevate. `status-interval 1` refreshes it.
  NOTE: `#(…)` jobs are async — a one-shot `tmux display-message -p '#(…)'` returns EMPTY the
  first time (the job hasn't finished), so test the script directly or via `tmux run-shell`,
  not display-message. The live status bar re-evaluates and caches, so it always populates.

### Tiling WM (both OSes)
- **The two keymaps are kept in sync — edit them as a pair.** `dot_config/skhd/skhdrc`
  (macOS/yabai) and `dot_config/whkd/whkdrc` (Windows/komorebi) share one mnemonic scheme
  (`alt`=focus, `alt+ctrl`=move, `[`/`]`=prev/next, numbers=jump) so muscle memory carries
  across machines. A change to one almost always needs the mirror change in the other; both
  files' headers document the scheme. Deliberate per-OS divergences (don't "fix" them to match):
  monitor-move is `⌃⌘←/→` on macOS but `win+shift+←/→` on Windows (Win+arrow=Snap, Win+P=
  Projection are reserved); macOS adds `⌥\`` recent-workspace, balance, sticky/pip (no komorebi
  verb).
- **yabai Space (workspace) binds need SIP partially disabled + the scripting addition** — with
  SIP on they silently no-op while every other bind still works (Accessibility only).

### CI (`.github/`)
- **Two workflows, split by cost.**
  - **`lint.yml`** runs on every push to `main` and every PR, skips `*.md`-only commits, and
    takes ~5s. It renders both bootstraps and runs `apply --dry-run`, which catches most
    mistakes.
  - **`e2e.yml`** runs a real `chezmoi init --apply` on ubuntu x64, ubuntu arm64, macOS and
    Windows. That takes minutes per OS and is network-heavy, so it is **path-filtered**: it
    runs only when something that changes WHAT GETS INSTALLED moves. That means `run_*`,
    `.chezmoi*`, the mise manifests, the sheldon and tmux plugin lists (the bootstrap clones
    them), `dot_claude/settings.json.tmpl` (the bootstrap renders its plugin ids from it), and
    the workflow file itself.
  - e2e also runs **weekly** (Mon 03:00 UTC) because every mise tool is `latest`, so an
    upstream release can break a fresh install without any commit here. It can also be
    started by hand with `workflow_dispatch`. If you add a file the bootstrap reads, add it to
    e2e's `paths` list.
  - arm64 is kept because it is the only job that catches a mise tool with no linux-arm64
    asset, which is what the Raspberry Pi needs.
  - Both workflows cancel a superseded run.
- **The verify step prints `chezmoi status` and `chezmoi diff` before it fails.** A bare
  `chezmoi verify` exits 1 with NO output, and that is why a red Ubuntu/macOS run went
  undiagnosed from `8afea8e` onward. Read the step log first, not the bootstrap.
- **A second `chezmoi apply --force` runs before verify, on purpose.** Cause:
  `claude plugin marketplace add` rewrites a newly added marketplace's entry in the MANAGED
  `~/.claude/settings.json` and DROPS its `autoUpdate: true` (`ponytail`, `last30days-skill`).
  It has no flag to keep it. Reproduced with a throwaway `CLAUDE_CONFIG_DIR`. An entry with no
  `autoUpdate` of its own, such as `anthropics/skills`, comes back byte-identical, which is why
  a first test against that marketplace showed nothing. It happens on the FIRST run only,
  because the adds are skipped once a marketplace is registered. The next `cza` restores the
  file, and the second apply in CI is exactly that `cza`. Verify then proves the setup
  converges and the bootstrap did not re-run. Fixing it inside the bootstrap was rejected for
  these reasons:
  - Writing the template back from the bootstrap would put the whole of `settings.json` into
    its run_onchange fingerprint.
  - Calling `chezmoi` from inside a chezmoi script would contend for the state lock.
  - Dropping `autoUpdate` from the template would lose the feature.
- **`e2e-windows` runs its steps in `pwsh` on purpose.** That reproduces the PSModulePath leak
  the bootstrap guards against (see Windows → Shell & env). Do not "simplify" the shell to
  `powershell`, because that would hide the bug again.
- **Renovate (`renovate.json`) updates GitHub Actions and nothing else**
  (`enabledManagers: ["github-actions"]`). Dependabot was removed so that only one bot runs.
  mise tools are deliberately NOT managed by Renovate: they stay `latest`/`lts`, and each
  machine upgrades them itself. Details:
  - **Location:** the file is at the repo root and is listed in `.chezmoiignore` beside
    README/CLAUDE.md. chezmoi applies every non-dot root file to `~/`, so without that entry it
    would land in `$HOME`. Check with `chezmoi managed | grep -c renovate`, which should print
    0. (`.github/renovate.json` is read just as well; location has no effect on the dashboard.)
  - **Dependency Dashboard:** it is on, because `config:recommended` enables it. It is one
    issue that lists pending, rate-limited and major updates, and it is the only place a held
    major shows up before you act on it.
  - **Pins:** `helpers:pinGitHubActionDigests` keeps every `uses:` pinned by SHA with a
    `# vX.Y.Z` comment. Renovate bumps both together.
  - **Automerge:** minor/patch/digest updates are grouped into one PR and merged by RENOVATE
    itself (`platformAutomerge: false`, `automergeType: pr`), and only after every check on
    the PR is green. Majors stay open for a human.
  - **Do NOT switch to GitHub-native automerge.** This repo has "Allow auto-merge" off and no
    branch protection on `main`. With no required checks, native auto-merge would merge
    immediately without waiting for CI.
  - **Do NOT use `automergeType: branch` either.** CI only triggers on pushes to `main` and on
    PRs, so a Renovate branch would have no checks to wait for.
  - **`minimumReleaseAge: 3 days`** is a supply-chain cooldown, so a release that gets pulled
    back never merges itself.
  - **Validate edits** with `npx -y --package renovate -- renovate-config-validator
    renovate.json`.
  - **Needs the Mend Renovate GitHub App installed on the repo.** Without it this file does
    nothing.

## Before committing
- ALWAYS update docs in the same commit as the change they describe:
  - `README.md` — anything user-facing (setup, usage, profiles, commands).
  - `CLAUDE.md` (this file) — naming conventions, profiles, tools split, workflow, gotchas.
- A commit that changes behavior, profiles, naming, or the bootstrap MUST NOT leave the docs stale.
