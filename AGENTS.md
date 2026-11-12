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
Render one template: `chezmoi execute-template < <source-file>`.

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
| `dot_config/{bat,fd,ripgrep,micro,git}` | CLI tool configs (`tools`) |
| `dot_zshrc`, `dot_p10k.zsh`, `dot_config/{zsh/conf.d,sheldon}` | Unix shell (numbered load order) |
| `dot_config/powershell/profile.ps1`, `dot_config/starship.toml` | Windows shell |
| `dot_config/mise/conf.d/*.toml` | tools/runtimes, all OSes |
| `dot_config/{yabai,skhd}` / `{komorebi,whkd,yasb}` | tiling WM: macOS / Windows |
| `dot_claude/`, `.chezmoitemplates/claude-settings.json` | Claude settings (merged), CLAUDE.md, statuslines |
| `dot_tmux.conf.tmpl`, `dot_local/bin/` | tmux + its helper scripts (Unix); psmux reads the same file (Windows blocks) |
| `.chezmoitemplates/alacritty.toml` | Alacritty, the terminal on Windows + Linux (macOS: Rex) (rendered to `~/.config/alacritty`; Windows' `%APPDATA%\alacritty` only imports it) |

## Profiles & OS
- Profile keys `tools`, `develop`, `tmux` (Linux; Windows = psmux; macOS = off, Rex), `wm` (macOS + Windows), `apps` — plus the
  Windows-only `sshd` (bool), `claudeServer` (bool, Linux + Windows: herdr + claude-rc at boot, opt-in per
  SSH server, never default) and strings `scoopDir`/`miseDataDir` — are prompted by
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
- **Which manager:** cross-platform CLI/runtime → mise; Windows-only CLI, font, WM, terminal →
  scoop; GUI app / installer / service / system runtime → winget (macOS: brew cask, Linux: apt).
  Never the same package in two managers. GUI apps install at the vendor's default path and
  scope — no `--location`/`--scope` (self-updaters write back to the default); only pin an
  installer (pwsh's MSI) when a config or task hardcodes the exe path.
- **`apps` profile** = the essential GUI apps in `.chezmoidata.yaml` `appList.<os>` (winget ids /
  brew casks; Linux: Tailscale + Brave Origin from vendor repos, hardcoded in the .sh bootstrap).
  Essentials only — anything else is installed by hand. winget runs
  with `--no-upgrade` (installed = `0x8A150061`, success); casks are guarded on `brew list --cask`.
- **scoop/brew/apt (+winget) only for tools ONE OS needs** (starship, psfzf, psmux, gsudo, fonts,
  WMs, mole, zsh, …) **and bootstrap prerequisites** that must exist before mise runs (git, curl,
  mise itself). Never move a cross-platform tool off mise on one OS — not even gh: the lists drift.
- OS package managers only for what mise can't do, installed only if missing: brew/apt `git curl
  tmux` (+`zsh` on Linux, `mole`/`yabai`/`skhd` on macOS; mole on Linux/Windows = its official
  installer into `~/.local/share/mole`, never mise — one repo tags all 3 OS builds); scoop `git mise openssl starship gsudo
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
  also ships in the managed settings; `RTK.md` is machine-local. The hook AUTO-ALLOWS any command a
  `permissions.allow` rule matches — keep that list read-only (`dot_claude/AGENTS.md` -> Settings).
- **codegraph** — mise `github:` bundle (own node). NEVER `codegraph install` (it writes into
  managed settings/CLAUDE.md). Bootstrap part 2 does `claude mcp add-json --scope user`
  (`alwaysLoad`; `cmd /c` on Windows — the launcher is a `.cmd`); part 1 appends `.codegraph/`
  to the unmanaged `~/.config/git/ignore`. Permission in `claude-settings.json`; the auto-init
  rule in `dot_claude/CLAUDE.md`.
- **agent-browser** = the agents' browser tool (mise `aqua:`): read `dot_agent-browser/AGENTS.md`.
- **agent-desktop** = the agents' desktop-app tool (mise `github:`; aqua registry lacks it). No
  policy file: NEVER auto-allow it (hook-enforced); its app rules are in `dot_claude/CLAUDE.md`.
- **delta** — wired by an idempotent `include.path` in the UNMANAGED `~/.gitconfig`; never
  manage `~/.gitconfig` (identity/signing stay machine-local).
- **Colours follow the terminal theme** — CLI configs use ANSI names only (fzf, tmux, bat/delta
  `ansi`, ripgrep, starship palette, micro `simple`, vivid `ansi`); never a hex/`colourNNN`, or a
  terminal theme change breaks them. zsh caches vivid's output and feeds completion `list-colors`.
- fzf-tab REQUIRES `zstyle ':completion:*' menu no` — never `menu select`.
- **Alacritty = the terminal** on Windows + Linux (one config: `.chezmoitemplates/alacritty.toml`); install
  paths, font and theme rules: `dot_config/alacritty/AGENTS.md`.
- **Rex** = the macOS terminal + multiplexer (replaces Alacritty and tmux there): `dot_config/rex/AGENTS.md`.
- Claude install / plugins / skills: read `dot_claude/AGENTS.md` before editing them.

## Windows
- **A failed step must fail the script** (both OSes): chezmoi never re-runs a `run_onchange` script
  that exited 0, so a swallowed failure leaves that tool missing for good. Windows: every install/
  network step goes through `Invoke-Step` + `Complete-Bootstrap`; Unix: part 1 `set -e`, part 2
  `fail()` + `exit 1`. Steps stay idempotent so the retry only redoes what's missing.
- **Before editing a `.ps1` bootstrap or any Windows setup step, read `.chezmoitemplates/AGENTS.md`**
  (preflight, `SCOOP`/`MISE_DATA_DIR`, `no_junction`, pwsh MSI, fonts, WinPS 5.1 quirks).
- **psmux** (tmux for Windows) + its session restore: read `dot_psmux/AGENTS.md` before editing
  `dot_psmux/`, the Windows blocks of `dot_tmux.conf.tmpl`, or the psmux steps of the `.ps1` bootstrap.
- `XDG_CONFIG_HOME=~/.config` is persisted on Windows and exported on Unix (`10-env.zsh`).
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
- tmux `#(…)` runs as the SERVER's user and is async — test the script directly, not via
  `display-message`.
- `skhdrc` (macOS) and `whkdrc` (Windows) share one keymap scheme — **edit them as a pair**.
  Deliberate divergences: monitor-move `⌃⌘←/→` vs `win+shift+←/→`; macOS-only recent-workspace,
  balance, sticky/pip; Windows has NO workspace binds — komorebi keeps ONE workspace per monitor,
  and `focus/move-to-workspace N` would create workspace N on demand. yabai Space binds need SIP
  partly off + the scripting addition.
- CI (workflows, verify, GITHUB_TOKEN, Renovate): `.github/AGENTS.md`. A new file the bootstrap
  reads goes into e2e's `paths`.
- Scripted edits on Windows: Python `write_text` writes CRLF — pass `newline="\n"` (or use Edit);
  a whole-file diff after a small change = line endings.

## Enforced NEVER rules (hook)
`.claude/hooks/never_rules.py` (PreToolUse, from the checked-in `.claude/settings.json`) blocks an
Edit/Write that adds a non-comment line breaking a NEVER rule above (mise env vars, baked pwsh
path, `conhost --headless`, `agentmemory connect`, winget/brew/npm Claude Code install, NanaZip,
fzf-tab `menu select`, 8-digit hex alpha in yasb CSS, risky Claude `permissions.allow` entries),
and edits to managed `$HOME` targets.
`*.md` and comments are exempt. A new rule = `RULES` entry + `selftest` case. `--selftest` and
`--scan` run in CI `lint`; `--scan` also catches `sed -i` edits the hook can't see.

## Before committing
Update docs in the SAME commit: `README.md` (user-facing), this file (conventions, profiles,
tools, gotchas), and the nested `AGENTS.md` beside what changed (`dot_claude/`,
`dot_config/{powershell,komorebi,yasb,mise}/`, `dot_agent-browser/`, `.chezmoitemplates/`, `.github/`).
Run `python .claude/hooks/never_rules.py --selftest && python .claude/hooks/never_rules.py --scan`
(CI `lint` does).

Where a rule goes: root = repo-wide conventions + one-line pointers; a tool with 3+ rules gets a
nested `AGENTS.md` beside its files. One rule, one place — link, never duplicate. AGENTS files are
shared across machines and OSes: no secrets, usernames, hostnames, absolute or drive paths,
versions or measurements that drift — write `~`/`$HOME`, placeholders and the stable rule.
