# AGENTS.md — dotfiles (chezmoi)

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
- **Non-`dot_` files (README.md, AGENTS.md) apply to `~/` unless in `.chezmoiignore`.**
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
- **Claude Code install, marketplaces/plugins, agent skills** (the Claude sections of both
  bootstraps and `run_after_update-claude-plugins.*`): read `dot_claude/AGENTS.md` BEFORE
  editing them — it holds the measured rules (`-y` flags, `extraKnownMarketplaces` presence
  loop, `false` = installed-but-off, `repo:skillspec:anchor` triples).

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
- **PowerShell profile** (PSReadLine/PSFzf gates, lazy loading, cached inits, the 500ms
  load budget): `dot_config/powershell/AGENTS.md`.
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
- **starship** (`scan_timeout`, what `starship timings` shows): `dot_config/powershell/AGENTS.md`.
- Skipped on Windows: tmux, sheldon, p10k, `.claude/statusline.sh` (Windows uses
  `.claude/statusline.ps1` instead — see `dot_claude/AGENTS.md`).

### Window manager (`wm` profile)
komorebi/whkd: `dot_config/komorebi/AGENTS.md`. yasb: `dot_config/yasb/AGENTS.md`.

## Gotchas

### chezmoi
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link
  with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`, and `apply`
  does NOT re-prompt profiles — edit that config or re-run `init`.

### mise
- **NEVER set `MISE_GLOBAL_CONFIG_FILE`** (nor `MISE_CONFIG_DIR`) — it silently stops conf.d
  discovery outside `$HOME`. Why, and the rest of the mise rules: `dot_config/mise/AGENTS.md`.

### Shell (zsh + pwsh)
- PowerShell alias-vs-function shadowing and the starship→zoxide init order:
  `dot_config/powershell/AGENTS.md`.
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
- Statusline per-OS port and the managed `settings.json.tmpl`: `dot_claude/AGENTS.md`.

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
- Workflows, verify step, GITHUB_TOKEN, Renovate: `.github/AGENTS.md`.

## Before committing
- ALWAYS update docs in the same commit as the change they describe:
  - `README.md` — anything user-facing (setup, usage, profiles, commands).
  - `AGENTS.md` (this file) — naming conventions, profiles, tools split, workflow, gotchas.
  - The nested `AGENTS.md` beside the files you changed (`dot_claude/`, `dot_config/{powershell,
    komorebi,yasb,mise}/`, `.github/`) — tool-specific gotchas live THERE, not here.
- A commit that changes behavior, profiles, naming, or the bootstrap MUST NOT leave the docs stale.
