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
  profile so XDG-aware tools read `~/.config` (mise's config dir resolves to `~/.config/mise`).
  Exported on every platform — Unix sets it in `zsh/conf.d/10-env.zsh` — so configs live under
  `~/.config` identically everywhere. (Do NOT set `MISE_GLOBAL_CONFIG_FILE` — it breaks conf.d
  outside `$HOME`; see the mise machine-local section below.)
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
- **NEVER set `MISE_GLOBAL_CONFIG_FILE`.** mise's default global config is already
  `~/.config/mise/config.toml`, so setting it is redundant — and it actively breaks `conf.d`:
  with it set, mise stops auto-discovering the global config DIRECTORY (the `conf.d/*.toml`
  tool manifests) whenever a shell's CWD is outside `$HOME` (e.g. a terminal whose start
  directory is a drive root). Symptom: `mise ls` shows tools with a blank config source —
  only `config.toml` is read. Proven by toggling the var from a dir outside `$HOME`. Leave it
  unset everywhere; the Windows bootstrap also CLEARS any stale User-scope value so old boxes
  heal. The profile/zsh env actively `unset` it too, so shells inheriting a stale value heal.
  (`MISE_CONFIG_DIR` is likewise unnecessary — mise resolves the config dir to `~/.config/mise`
  on its own. Don't reintroduce either var to "pin" conf.d; pinning is what caused the bug.)
- `.config/mise/config.toml` is in `.chezmoiignore` → chezmoi never manages it, and `mise use
  -g` writes there by DEFAULT (no env var needed), so ad-hoc per-machine pins survive `apply`.
  NEVER let `mise use -g` land in a tracked `conf.d/*.toml` (it makes `apply` prompt "changed
  since chezmoi last wrote it" and reverts the pin).
- mise only auto-discovers the global `conf.d/*.toml` when CWD is inside `$HOME`; the bootstraps
  therefore run `mise --cd $HOME install` so a fresh-machine install isn't blank when chezmoi
  runs the script from elsewhere. The PowerShell profile already injects tools via
  `mise --cd $HOME env`, so tools work in every shell regardless of its start directory.

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
- **tmux plugins install via `git clone` in the bootstrap — no tmux server.** Do NOT
  "fix" it to use TPM's `bin/install_plugins`: that needs a live server that has sourced
  the config (for `TMUX_PLUGIN_MANAGER_PATH`); during a non-interactive bootstrap a
  session-less `tmux start-server` exits first → TPM aborts "not configured" → 0 plugins,
  AND it leaves a stale server on the default socket → plain `tmux` then dies with
  "server exited unexpectedly" after the next tmux upgrade (old server vs new client).
  A "plugin install" is just a clone into `~/.tmux/plugins/<name>`, so the bootstrap parses
  `@plugin` lines and clones them. After upgrading tmux, `tmux kill-server` (or relog) to
  drop a stale old-version server.
- **PowerShell resolves ALIASES before FUNCTIONS.** A `function ls { eza … }` in the profile
  is silently shadowed by the shipped `ls`→Get-ChildItem alias (so `ls` keeps built-in output
  even though the function exists). The eza block therefore `Remove-Item Alias:ls -Force` before
  defining the function. Only `ls` collides with a built-in alias (la/ll/lt/lm/… don't; `tree`
  is an .exe, which a function already outranks). zsh is unaffected — it uses `alias ls=…`, not
  a function. If you add a new eza/tool function whose name is also a default PS alias, drop the
  alias too. (`Get-Command ls` showing `CommandType: Alias` instead of `Function` = the bug.)
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`.
- `apply` does NOT re-prompt profiles — edit the config or re-run `init`.
- **Setting an env var to a tool's OWN DEFAULT is not a harmless no-op — don't do it "for
  explicitness".** A tool that auto-discovers config by walking/scanning a directory often
  switches to single-file / narrowed mode the moment you hand it an explicit path. That was
  this repo's `MISE_GLOBAL_CONFIG_FILE` bug: pointing it at mise's own default
  `~/.config/mise/config.toml` silently disabled `conf.d` auto-discovery outside `$HOME`. If
  the value equals the default, DELETE the assignment — rely on the default and only override
  when you genuinely need a non-default. Prefer adding a guard/`unset` over re-asserting.
- **Reproduce context-sensitive bugs in the ACTUAL failing context, and verify env fixes in a
  FRESH process tree.** This bug only appeared when CWD was outside `$HOME` (terminals start at
  a drive root); testing from the repo dir (inside `$HOME`) hid it and produced a wrong first
  diagnosis. And a child shell inherits the parent's stale env — a "fix" can look broken (var
  still set) or look fixed (var still good) purely from inheritance. Launch a clean shell, cd
  to the real failing dir, and check the variable's value, before concluding anything.
