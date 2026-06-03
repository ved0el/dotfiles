# CLAUDE.md — dotfiles (chezmoi)

Personal dotfiles managed by [chezmoi](https://chezmoi.io). Files in this source
dir are applied to `$HOME`. Repo: `ved0el/dotfiles`.

## Naming conventions
- `dot_X` → `~/.X`; `executable_X` → +x; `private_X` → 0600; `*.tmpl` → Go-templated.
- `run_onchange_after_install-packages.sh.tmpl` — bootstrap (packages + plugins);
  re-runs when its rendered content changes; `after_` = runs once files are applied.
- **Non-`dot_` files (README.md, CLAUDE.md) apply to `~/` unless in `.chezmoiignore`.**

## Profiles (per-machine toggles)
- Data keys: `tools`, `develop`, `tmux` (Unix only), `wm` (macOS + Windows).
- Chosen by `chezmoi init` prompts in `.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`
  (overrides the `.chezmoidata.yaml` defaults). Re-run `chezmoi init` to change them.
- `.chezmoiignore` gates which files apply; the bootstrap gates installs by the same keys.
- Templates reference `.tools/.develop/.tmux/.wm` — they MUST exist or rendering errors
  ("map has no entry for key …"). `.chezmoidata.yaml` guarantees they exist.
- `tmux` is prompted only on non-Windows (forced `false` on Windows). `wm` is prompted on
  macOS (yabai + skhd) and Windows (komorebi + whkd + yasb); forced `false` on Linux.

## OS gate (NOT a prompt — auto-detected via `.chezmoi.os`)
- Three values: `windows` / `darwin` / `linux`. Never prompt for the OS; branch on it.
- **Bootstrap is split by OS family, one script each:**
  - `run_onchange_after_install-packages.sh.tmpl` — macOS (brew) + Linux (apt).
  - `run_onchange_after_install-packages.ps1.tmpl` — Windows (scoop).
  - `.chezmoiignore` ships exactly one (ignores `install-packages.ps1` on Unix and
    `install-packages.sh` on Windows — script target names drop the `run_*`/`.tmpl`).
    A `.sh` on Windows is unrunnable ("%1 is not a valid Win32 application"), so it MUST
    be ignored, not just rendered empty (the shebang line keeps it non-empty).
- chezmoi runs `.ps1` via `[interpreters.ps1]` (set Windows-only in `.chezmoi.toml.tmpl`):
  `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass` (5.1 is guaranteed on a fresh
  box; the bootstrap then installs pwsh 7).

## Windows specifics
- **scoop** is the PM (per-user, never elevated): `git`, `pwsh`, `mise`. CLI tools still
  come from **mise** (same `conf.d/*.toml` as Unix — one list).
- **`XDG_CONFIG_HOME=~/.config`** is persisted (user env) by the bootstrap + set in the
  profile, so mise reads `~/.config/mise/conf.d` (it would otherwise use `%APPDATA%`).
  Exported on every platform — Unix sets it in `zsh/conf.d/10-env.zsh` — so configs live
  under `~/.config` identically everywhere.
- **PowerShell profile**: managed at `dot_config/powershell/profile.ps1`
  (→ `~/.config/powershell/profile.ps1`). The bootstrap dot-sources it from the real
  `$PROFILE` (both pwsh 7 and WinPS 5.1 paths, via OneDrive-aware `GetFolderPath`).
  Edit the managed file, not `$PROFILE`.
- **Window manager** (`wm` profile): scoop installs `komorebi whkd yasb` (extras bucket);
  configs `dot_config/{whkd,komorebi,yasb}` apply only on Windows+wm (gated like skhd/yabai).
  `KOMOREBI_CONFIG_HOME`/`WHKD_CONFIG_HOME`/`YASB_CONFIG_HOME` → `~/.config/<tool>`, persisted
  (User scope) by the bootstrap because these apps launch at startup, outside any shell
  profile — komorebi else defaults to `~/komorebi.json`, whkd to `~/.config/whkdrc`.
  yasb's `config.yaml.tmpl` is templated — user paths use
  `{{ .chezmoi.homeDir | replace "/" "\\" }}` (NEVER hardcode the username).
- Skipped on Windows: tmux, sheldon, p10k, nano.

## Tools split
- CLI tools + language runtimes → **mise** (`dot_config/mise/conf.d/{tools,develop}.toml`),
  cross-platform (macOS/Ubuntu/Raspberry Pi — one list, no per-OS name gaps).
- `conf.d/windows.toml` — Windows-only mise tools (e.g. starship; gated off in `.chezmoiignore`).
- Base via **OS PM** (brew/apt), installed only if missing: `git`, `curl`, `tmux`; macOS adds
  `mole` (cleanup CLI) and `yabai`/`skhd` (wm). No more `btop`/`tree`/`wget` — `btop`→`bottom`
  (mise) and `tree`→`eza -T` alias.
- Windows base → **scoop** (`git pwsh mise`) in the `.ps1` bootstrap.
- Prefer prebuilt backends for cross-platform tools: `"aqua:eza-community/eza"`, not bare
  `eza` (registry default is `cargo:eza` — source build, no Windows binary).

## mise machine-local config (un-tracked)
- `MISE_GLOBAL_CONFIG_FILE` → `~/.config/mise/config.toml` (set in `zsh/conf.d/10-env.zsh`,
  the PowerShell profile, and the Windows bootstrap). `mise use -g` writes THERE.
- `.config/mise/config.toml` is in `.chezmoiignore` → chezmoi never manages it, so ad-hoc
  per-machine pins survive `apply`. NEVER let `mise use -g` land in a tracked `conf.d/*.toml`
  (it makes `apply` prompt "changed since chezmoi last wrote it" and reverts the pin).

## Verify before apply
- `chezmoi execute-template '{{ .tools }}|{{ .develop }}|{{ .tmux }}|{{ .wm }}'` — resolved profile data.
- `chezmoi cat-config` — the per-machine config that wins.
- `chezmoi apply -n -v` — dry-run diff. NOTE: the bootstrap script's text (e.g. `skhd`) shows in
  the diff; grep config paths like `^diff --git a/.config/...` to judge actual file application.
- `chezmoi managed | grep X` / `chezmoi ignored` — confirm what applies vs is excluded.

## Before committing
- ALWAYS update docs in the same commit as the change they describe:
  - `README.md` — anything user-facing (setup, usage, profiles, commands).
  - `CLAUDE.md` (this file) — naming conventions, profiles, tools split, workflow, gotchas.
- A commit that changes behavior, profiles, naming, or the bootstrap MUST NOT leave the docs stale.

## Gotchas
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`.
- `apply` does NOT re-prompt profiles — edit the config or re-run `init`.
