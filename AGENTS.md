# AGENTS.md — dotfiles (chezmoi)

Personal dotfiles managed by [chezmoi](https://chezmoi.io); this source dir is applied to
`$HOME`. Repo: `ved0el/dotfiles`. Rules here are terse on purpose (this file loads into every
session); the measured "why" behind each one is in its commit — `git log -S '<keyword>'`.
Tool-specific rules live in the nested `AGENTS.md` beside the files.

## Commands
**Edit files HERE, never the `$HOME` target** — `apply` overwrites it (the hook enforces this).
`czra` captures a `$HOME` edit back, but not for `.tmpl`/`modify_` targets.

| alias | command | use |
|---|---|---|
| `cza` | `chezmoi apply` | source → `$HOME`; re-runs a bootstrap script whose rendered content changed (installs missing plugins, never updates) |
| `czd` / `czs` | `diff` / `status` | preview; `R` in status = a script will run |
| `czra` | `re-add` | capture a `$HOME` edit |
| `czu` | `update` | git pull + apply; the ONLY command that updates Claude plugins/skills |
| `cz`, `cze`, `czcd` | `chezmoi`, `edit`, `cd` | passthrough / `$EDITOR` / cd into repo |

Aliases: `dot_config/zsh/conf.d/70-aliases.zsh`, `dot_config/powershell/profile.ps1`.
Check before apply: `chezmoi execute-template '{{ .tools }}|{{ .develop }}|{{ .tmux }}|{{ .wm }}'`,
`chezmoi cat-config`, `chezmoi apply -n -v` (script text shows in the diff — grep
`^diff --git a/.config/` for real file changes), `chezmoi managed` / `chezmoi ignored`.

## Layout
- `dot_X` → `~/.X`, `executable_` → +x, `private_` → 0600, `*.tmpl` → Go template,
  `.chezmoitemplates/` → shared templates for `includeTemplate` (never applied).
- **Non-`dot_` files (README.md, AGENTS.md) apply to `~/` unless listed in `.chezmoiignore`.**
- **Bootstrap = two `run_onchange_after_` scripts per OS family** (`.sh.tmpl` for brew/apt,
  `.ps1.tmpl` for scoop), run in name order after files apply, each re-running only when ITS
  rendered content changes:
  - `10-install-packages` — OS packages, mise, tmux/zsh plugins, git wiring, wm, pwsh profile.
  - `20-install-claude` — Claude Code, marketplaces/plugins/skills, rtk hook, codegraph MCP.
  - Separate processes: part 2 re-adds `~/.local/bin` (+ scoop shims, `XDG_CONFIG_HOME` on
    Windows) to its own env.
  - `.chezmoiignore` ships one set per OS (`*-install-*.ps1` ignored on Unix, `.sh` on Windows);
    a `.sh` can't run on Windows, so it MUST be ignored, not rendered empty.
- `run_after_update-claude-plugins.*` — hidden from every command except `chezmoi update`.

| path | holds |
|---|---|
| `dot_config/{bat,fd,ripgrep,micro,git,vivid}` | CLI tool configs (`tools`) |
| `dot_zshrc`, `dot_p10k.zsh`, `dot_config/{zsh/conf.d,sheldon}` | Unix shell (numbered load order) |
| `dot_config/powershell/profile.ps1`, `dot_config/starship.toml` | Windows shell |
| `dot_config/mise/conf.d/*.toml` | tools/runtimes, all OSes |
| `dot_config/{yabai,skhd}` / `{komorebi,whkd,yasb}` | tiling WM: macOS / Windows |
| `dot_claude/`, `.chezmoitemplates/claude-settings.json` | Claude settings (merged), CLAUDE.md, statuslines |
| `dot_tmux.conf.tmpl`, `dot_local/bin/` | tmux + its helper scripts (Unix); psmux reads the same file (Windows blocks) |
| `AppData/…/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/modify_settings.json`, `.chezmoitemplates/windows-terminal.json` | Windows Terminal (merged into the live file) |

## Profiles & OS
- Profile keys `tools`, `develop`, `tmux` (Windows = psmux), `wm` (macOS + Windows) — plus the
  Windows-only strings `scoopDir`/`miseDataDir` — are prompted by
  `chezmoi init` (`.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`, which overrides
  `.chezmoidata.yaml`). `apply` never re-prompts: re-run `init` or edit that file.
- `.chezmoidata.yaml` must define every key — templates error on a missing one.
- `.chezmoiignore` gates files; the bootstraps gate installs by the same keys.
- OS is auto-detected (`.chezmoi.os` = windows/darwin/linux) — branch on it, never prompt.
- `.ps1` scripts run under **WinPS 5.1** at its fixed System32 path (`[interpreters.ps1]`), never pwsh.
- **NEVER bake an absolute pwsh path** into `.chezmoi.toml.tmpl` (nor `lookPath "pwsh"`): pwsh
  moves between install sources. `[cd]` uses bare `pwsh`, resolved on PATH at runtime.

## Tools
- CLI tools + runtimes → **mise** (`conf.d/tools.toml.tmpl`, `develop.toml`; Windows-only
  extras in `windows.toml`). Prefer prebuilt backends (`aqua:`/`github:`) over source builds;
  the backend prefix goes in the KEY. `eza` is `aqua:` on Windows only (registry default is cargo).
- OS package managers only for what mise can't do, installed only if missing: brew/apt `git curl
  tmux` (+`zsh` on Linux, `mole`/`yabai`/`skhd` on macOS); scoop `git mise openssl gsudo
  JetBrainsMono-NF-Mono psfzf` (+`psmux` for `tmux`); winget `Microsoft.PowerShell`. Guard on the
  COMMAND (a font/module: on `scoop list | Out-String` — `Select-String` on its objects never matches).
- **ssh on Windows = the built-in OpenSSH** (System32, pairs with the `ssh-agent` service), never
  scoop `openssh`; git uses it via `core.sshCommand` (set only if unset).
- `chsh` is never run (password prompt hangs the bootstrap); the script prints the command.
- **NanaZip / the archive extractor is NOT managed** — no `scoop install nanazip`, no 7z shim,
  no `use_external_7zip`. scoop pulling its own 7zip is fine.
- **rtk** — `rtk init -g --auto-patch` (`--auto-patch` is required: non-interactive). Its hook
  also ships in the managed settings; `RTK.md` is machine-local.
- **codegraph** — mise `github:` bundle (own node). NEVER `codegraph install` (it writes into
  managed settings/CLAUDE.md). Bootstrap part 2 does `claude mcp add-json --scope user`
  (`alwaysLoad`; `cmd /c` on Windows — the launcher is a `.cmd`); part 1 appends `.codegraph/`
  to the unmanaged `~/.config/git/ignore`. Permission in `claude-settings.json`; the auto-init
  rule in `dot_claude/CLAUDE.md`.
- **delta** — wired by an idempotent `include.path` in the UNMANAGED `~/.gitconfig`; never
  manage `~/.gitconfig` (identity/signing stay machine-local).
- **vivid** — needs a COMPLETE theme (`dot_config/vivid/themes/catppuccin-mocha-red.yml`);
  zsh caches its output and feeds completion `list-colors`.
- fzf-tab REQUIRES `zstyle ':completion:*' menu no` — never `menu select`.
- Claude install / plugins / skills: read `dot_claude/AGENTS.md` before editing them.

## Windows
- **`SCOOP` / `MISE_DATA_DIR` are User scope, set BEFORE installing** (the installers read them;
  default `~/.local/share/{scoop,mise}`); their shims go on User PATH. An existing root elsewhere
  is kept with a warning — never moved (scoop's shims/junctions hold absolute paths). Part 2 is a
  separate process: it reloads both from User env. `MISE_DATA_DIR` is NOT a NEVER var.
- **Windows Terminal is merged, never replaced** (`modify_` + `fromJsonc` — a WT-written file has
  `//` comments): curated keys win, lists are replaced, `profiles.list` is the curated profiles
  merged per `guid` over the live ones (icons survive). Its font must be one the bootstrap installs.
- **psmux** reads `~/.tmux.conf`; Windows-only lines are `{{ if eq .chezmoi.os "windows" }}` blocks
  in `dot_tmux.conf.tmpl`. Plugins are copied from the `psmux/psmux-plugins` monorepo into
  `~/.psmux/plugins/` (their `plugin.conf` hardcodes that path) — keep the bootstrap list and the
  `@plugin` lines in sync. Not ported: the sessionizer (`C-a f`), `tmux-user`.
- WinPS 5.1 is an OS component — never "remove" it; pwsh's profile only aliases `powershell` → `pwsh`.
- scoop is per-user and never elevated. **pwsh 7 comes from winget** (MSIX, per-user, no admin);
  flags `--silent --accept-package-agreements --accept-source-agreements --disable-interactivity`.
  An existing pwsh is never replaced.
- Every `.ps1` bootstrap **resets `PSModulePath` to 5.1's own list first** — inherited from pwsh
  7, 5.1 autoloads pwsh's modules and dies (only when pwsh's `$PSHOME` is readable, e.g. CI).
- A module the pwsh profile needs comes **from scoop** (PSFzf = extras `psfzf`): scoop's
  `<scoop>\modules` is on the USER PSModulePath, seen by both 5.1 and 7. NEVER `Install-Module`/
  `Install-PSResource` from the 5.1 bootstrap — 5.1 and 7 don't see each other's CurrentUser modules.
- WinPS 5.1 strips `"` from native args — escape JSON as `\"` (see the codegraph MCP add).
- Under `$ErrorActionPreference = 'Stop'`, 5.1 turns a native command's REDIRECTED stderr
  (`2>$null`, `*>`) into a terminating error. Probe native exit codes inside
  `& { $ErrorActionPreference = 'Continue'; <cmd> 2>&1 | Out-Null; $LASTEXITCODE -eq 0 }`.
- `XDG_CONFIG_HOME=~/.config` is persisted on Windows and exported on Unix (`10-env.zsh`).
- `powershell.exe` "not recognized" = `System32\WindowsPowerShell\v1.0` fell off PATH; add it to
  the User PATH by hand (not a bootstrap step).
- Profile, PSReadLine/PSFzf, starship, load budget: `dot_config/powershell/AGENTS.md`.
  WM: `dot_config/komorebi/AGENTS.md`, `dot_config/yasb/AGENTS.md`.

## Gotchas
- chezmoi **copies**, never symlinks.
- mise: **NEVER set `MISE_GLOBAL_CONFIG_FILE` / `MISE_CONFIG_DIR`** — it breaks conf.d discovery
  outside `$HOME` (`dot_config/mise/AGENTS.md`). Run mise from scripts as `mise --cd "$HOME"`.
- `cd` → zoxide on both shells is skipped when `CLAUDECODE` is set: a zoxide miss would leak
  `zoxide: no match found` into Claude's piped output.
- tmux plugins are `git clone`d by the bootstrap. Do NOT switch to TPM's `install_plugins` — it
  needs a live server, installs 0 plugins non-interactively and leaves a stale server behind.
- tmux `#(…)` runs as the SERVER's user; `tmux-user` reads the pane tty's foreground process
  instead. `#(…)` is async — test the script directly, not via `display-message`.
- `skhdrc` (macOS) and `whkdrc` (Windows) share one keymap scheme — **edit them as a pair**.
  Deliberate divergences: monitor-move `⌃⌘←/→` vs `win+shift+←/→`; macOS-only recent-workspace,
  balance, sticky/pip. yabai Space binds need SIP partly off + the scripting addition.
- CI (workflows, verify, GITHUB_TOKEN, Renovate): `.github/AGENTS.md`. A new file the bootstrap
  reads goes into e2e's `paths`.

## Enforced NEVER rules (hook)
`.claude/hooks/never_rules.py` (PreToolUse, from the checked-in `.claude/settings.json`) blocks an
Edit/Write that adds a non-comment line breaking a NEVER rule above (mise env vars, baked pwsh
path, `conhost --headless`, `claude-mem install`, winget/brew/npm Claude Code install, NanaZip,
fzf-tab `menu select`, 8-digit hex alpha in yasb CSS), and edits to managed `$HOME` targets.
`*.md` and comments are exempt. A new rule = `RULES` entry + `selftest` case. `--selftest` and
`--scan` run in CI `lint`; `--scan` also catches `sed -i` edits the hook can't see.

## Before committing
Update docs in the SAME commit: `README.md` (user-facing), this file (conventions, profiles,
tools, gotchas), and the nested `AGENTS.md` beside what changed (`dot_claude/`,
`dot_config/{powershell,komorebi,yasb,mise}/`, `.github/`).
