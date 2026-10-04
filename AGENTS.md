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
| `czu` | `update` | git pull + apply (installs what's missing; never updates plugins/skills — that's the user's, in Claude) |
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
  Windows-only `sshd` (bool) and strings `scoopDir`/`miseDataDir` — are prompted by
  `chezmoi init` (`.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`, which overrides
  `.chezmoidata.yaml`). `apply` never re-prompts: re-run `init` or edit that file.
- `.chezmoidata.yaml` must define every key — templates error on a missing one.
- `.chezmoiignore` gates files; the bootstraps gate installs by the same keys.
- OS is auto-detected (`.chezmoi.os` = windows/darwin/linux) — branch on it, never prompt.
- `.ps1` scripts run under **WinPS 5.1** at its fixed System32 path (`[interpreters.ps1]`), never pwsh.
- **NEVER bake an absolute pwsh path** into `.chezmoi.toml.tmpl` (nor `lookPath "pwsh"`): pwsh
  moves between install sources. `[cd]` uses bare `pwsh`, resolved on PATH at runtime.

## Tools
- **mise is the main manager — one tool list for every OS.** Every cross-platform CLI tool and
  runtime goes there (`conf.d/tools.toml.tmpl`, `develop.toml`); a cross-platform tool that only
  needs a different BACKEND on Windows goes in `windows.toml` (`eza` is `aqua:` there; registry
  default is cargo). Prefer prebuilt backends (`aqua:`/`github:`); the prefix goes in the KEY.
- **scoop/brew/apt (+winget) only for tools ONE OS needs** (starship, psfzf, psmux, gsudo, fonts,
  WMs, mole, zsh, …) **and bootstrap prerequisites** that must exist before mise runs (git, curl,
  mise itself). Never move a cross-platform tool off mise on one OS — not even gh: the lists drift.
- OS package managers only for what mise can't do, installed only if missing: brew/apt `git curl
  tmux` (+`zsh` on Linux, `mole`/`yabai`/`skhd` on macOS); scoop `git mise openssl starship gsudo
  JetBrainsMono-NF psfzf` (+`psmux` for `tmux`); winget `Microsoft.PowerShell` + `Microsoft.VCRedist.2015+.{x64,x86}` (+arm64) — always run:
  `winget install` upgrades an installed package, exit `0x8A15002B`/`0x8A150061` = already current. Guard on the
  COMMAND (a module: on `scoop list | Out-String` — `Select-String` on its objects never matches; a
  FONT: on its `.ttf` in the user/system Fonts dir — a registered font file is held open, so
  re-running scoop's font install over it fails "being used by another process").
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
- **A failed step must fail the script** — chezmoi records a `run_onchange` script that exits 0
  and never re-runs it, so a swallowed failure (try/catch + Write-Host, an unchecked
  `$LASTEXITCODE`) leaves that tool missing for good. Every install/network step goes through
  `Invoke-Step` (`.chezmoitemplates/bootstrap-steps.ps1`: runs under `Continue`, counts a throw
  or non-zero exit) and each part ends with `Complete-Bootstrap` (`exit 1` if any failed). Steps
  stay idempotent so the retry only redoes what's missing. README's one-liner uses `--keep-going`
  so a failed part 1 doesn't skip part 2; part 2 itself stops when part 1 left no mise.
- **Preflight, before changing anything** (part 1): exit on an elevated terminal (scoop's
  installer `break`s out mid-way; `$env:CI` is exempt, as in scoop's own check) and, when pwsh is
  missing, on a winget that isn't ready (new account) — NO scoop-pwsh fallback; the user updates
  App Installer and re-runs.
- Part 1 also sets: CurrentUser `RemoteSigned` for WinPS 5.1 (default Restricted blocks its
  profile + scoop shims) only if unset; `CLAUDE_CODE_GIT_BASH_PATH` → scoop's versioned `bash.exe`
  (Claude can't derive it from the `git.exe` shim) if unset or still pointing into scoop's git
  elsewhere (the old `current` junction fails over SSH). `bootstrap-steps.ps1`'s `Set-GitHubToken`
  exports a logged-in gh's token (gh = a mise tool) as `GITHUB_TOKEN` for mise's API calls;
  part 1 calls it again right before `mise install`, once mise's shims are on PATH.
- **`SCOOP` / `MISE_DATA_DIR` are User scope, set BEFORE installing** (the installers read them;
  default `~/.local/share/{scoop,mise}`); their shims go on User PATH. An existing root elsewhere
  is kept with a warning — never moved (scoop's shims/junctions hold absolute paths). Part 2 is a
  separate process: it reloads both from User env. `MISE_DATA_DIR` is NOT a NEVER var.
- **scoop `no_junction`** — `sshd` profile only (its one-time `scoop reset *` fails while an app runs, so clients skip it); set before any install; a junction-era install is `scoop reset *` once:
  sshd runs with RedirectionGuard, which won't follow a non-admin junction, so a shim through
  `apps\<app>\current` fails over SSH (Scoop#6594). So paths are versioned: never hardcode
  `apps\<app>\current` (use `scoop prefix <app>`). An app's `persist` junctions aren't covered.
- **Windows Terminal is merged, never replaced** (`modify_` + `fromJsonc` — a WT-written file has
  `//` comments): curated keys win, lists are replaced, `profiles.list` is the curated profiles
  merged per `guid` over the live ones (icons survive). Its font must be one the bootstrap installs
  — check the FAMILY NAME the package registers (its manifest's `-Filter`, then the .ttf's name
  table), not just the files it ships: `JetBrainsMono-NF` → `JetBrainsMonoNL Nerd Font`,
  `-NF-Mono` → only `… Nerd Font Mono`. A WT open during the first apply warns once (the file
  lands before part 1 installs the font); reopening WT clears it.
- **psmux** reads `~/.tmux.conf`; Windows-only lines are `{{ if eq .chezmoi.os "windows" }}` blocks
  in `dot_tmux.conf.tmpl`. Plugins are copied from the `psmux/psmux-plugins` monorepo into
  `~/.psmux/plugins/` (their `plugin.conf` hardcodes that path) — keep the bootstrap list and the
  `@plugin` lines in sync. Not ported: the sessionizer (`C-b f`), `tmux-user`.
  Its border label is a literal replace of `#{pane_title}`/`#{pane_index}`/`#P` only (`#P` = pane
  id), so the pane name is the pane title (`allow-set-title`; the pwsh profile sets `pane<id>`).
  `window-(active-)style` is ignored by the 3.3.8 client; no extended-keys, so `C-Enter` is bound to `send-keys C-j`. No `psmux-cpu` (pwsh every status tick).
  Restore = profile `tm` (auto-run at the end of the profile on an interactive SSH login — not `pwsh -c`,
  psmux, `CLAUDECODE`), run whenever a saved session isn't running (`psmux ls` exits 0 with no server —
  test its output) (`@continuum-restore` off: one server per session re-fires its once-per-server
  guard); `node` panes go through `~/.psmux/strategies/node_claude.ps1` (title → `custom-title` →
  `Set-Location <dir>; claude --resume` — cd first, a warm pane's own `cd` can lose the race, else a comment line — never empty, resurrect falls back to `node`).
- WinPS 5.1 is an OS component — never "remove" it; pwsh's profile only aliases `powershell` → `pwsh`.
- scoop is per-user and never elevated. **pwsh 7 comes from winget's MSI** (`--installer-type wix
  --scope machine`, one UAC prompt) at the FIXED `$env:ProgramFiles\PowerShell\7` — NOT winget's
  default MSIX, whose `WindowsApps\Microsoft.PowerShell_<version>_…` dir moves on every update.
  Guarded on that path (an MSIX pwsh doesn't count); success = the file exists. A leftover MSIX is
  only reported, never removed by the bootstrap (it usually runs from that pwsh). Flags also
  `--silent --accept-package-agreements --accept-source-agreements --disable-interactivity`.
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
