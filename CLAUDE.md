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
- Skipped on Windows: tmux, sheldon, p10k, `.claude/statusline.sh` (Windows uses
  `.claude/statusline.ps1` instead — see the statusline-flash gotcha).

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
- **`rtk` (rtk-ai/rtk) uses the mise `github:` backend** (`github:rtk-ai/rtk` — prebuilt release
  binary; the older `ubi:` backend works but mise deprecated it). Beyond install, the bootstrap
  runs `rtk init -g --auto-patch` to register rtk's Claude Code command-rewrite hook globally.
  `--auto-patch` is REQUIRED: it patches `~/.claude/settings.json` without prompting, so the
  non-interactive bootstrap doesn't hang. It's idempotent ("hook already present" on re-run) and
  writes machine-local `~/.claude/RTK.md`. The rtk PreToolUse hook now also ships in the managed
  `dot_claude/settings.json`, so the run finds it already present — `--auto-patch` mainly handles
  RTK.md + acts as a safety net.
- **Claude plugin marketplaces are cloned/updated by the bootstrap via `claude plugin
  marketplace update`.** That command reads the chezmoi-managed `dot_claude/settings.json`
  `extraKnownMarketplaces`, so that file is the single source of truth — no duplicate list in
  the script. Plugins ship inside their marketplace repos, so updating the marketplaces also
  refreshes plugin code; `enabledPlugins` just toggles them. The bootstrap line carries a
  `# marketplaces fingerprint:` comment (sha256 of the `extraKnownMarketplaces` slice via
  `fromJson`), so the run_onchange script re-fires on the next `cza` whenever you add/remove a
  marketplace — newly-declared ones get cloned, not just the existing ones pulled. Add a
  marketplace by editing `extraKnownMarketplaces` (or `czra` to capture Claude's live edit),
  then `cza`. Gated `|| true` / `try/catch` so a network blip or a not-yet-installed `claude`
  never aborts setup.
- **`vivid` generates `LS_COLORS`; `delta` is wired into git via an include, NOT a managed
  `~/.gitconfig`.** vivid uses the mise `github:` backend (prebuilt). Its theme is the full
  upstream catppuccin-mocha with `red`→repo accent `#ff5189` (`dot_config/vivid/themes/
  catppuccin-mocha-red.yml`; vivid needs a COMPLETE theme — a minimal override errors). zsh
  (`75-tools.zsh`) caches `vivid generate` to `$ZSH_CACHE_DIR/ls_colors` (regenerated when the
  theme changes) and feeds it to completion via `list-colors` (read at completion time, so it
  works despite running after compinit). delta config lives in tracked `dot_config/git/
  delta.gitconfig`; the bootstrap adds an idempotent `include.path` to the UNMANAGED `~/.gitconfig`
  (identity/signing stay machine-local), gated `{{ if .tools }}`. `git config --global X` won't
  show included values without `--includes`, but real `git diff`/`log` follow the include fine.
  Both vivid + delta configs are tools-profile gated in `.chezmoiignore` (`.config/vivid`,
  `.config/git`). Completion uses fzf-tab (sheldon plugin, deferred) — it REQUIRES
  `zstyle ':completion:*' menu no` (never `menu select`); its `:fzf-tab:*` zstyles + eza/bat
  previews live in `50-completions.zsh` and inherit the catppuccin `FZF_DEFAULT_OPTS` via
  `use-fzf-default-opts`.

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
- **tmux status-bar `#(…)` runs as the SERVER's user, not the pane's.** So the old
  `status-left … #(whoami)` froze on the login that started the server and never tracked
  `sudo -i`/`su -`. Fix: `~/.local/bin/tmux-user` (`executable_tmux-user`, tmux-only — ignored
  on Windows like `tmux-sessionizer`) takes `#{pane_tty}` and reports the owner of the tty's
  FOREGROUND process group (the first proc with `+` in STAT — works on BSD/macOS + GNU/Linux),
  so the bar switches to `root` the moment you elevate. `status-interval 1` refreshes it.
  NOTE: `#(…)` jobs are async — a one-shot `tmux display-message -p '#(…)'` returns EMPTY the
  first time (the job hasn't finished), so test the script directly or via `tmux run-shell`,
  not display-message. The live status bar re-evaluates and caches, so it always populates.
- **The two tiling-WM keymaps are kept in sync — edit them as a pair.** `dot_config/skhd/skhdrc`
  (macOS/yabai) and `dot_config/whkd/whkdrc` (Windows/komorebi) share one mnemonic scheme
  (`alt`=focus, `alt+ctrl`=move, `[`/`]`=prev/next, numbers=jump) so muscle memory carries
  across machines. A change to one almost always needs the mirror change in the other; both
  files' headers document the scheme. Deliberate per-OS divergences (don't "fix" them to match):
  monitor-move is `⌃⌘←/→` on macOS but `win+shift+←/→` on Windows (Win+arrow=Snap, Win+P=
  Projection are reserved); macOS adds `⌥\`` recent-workspace, balance, sticky/pip (no komorebi
  verb). **yabai Space (workspace) binds need SIP partially disabled + the scripting addition** —
  with SIP on they silently no-op while every other bind still works (Accessibility only).
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
  missing a dir you just visited = the bug. NOTE when testing: `pwsh -Command` already auto-loads
  the profile once, so an extra `. $PROFILE` double-loads it — the second starship init replaces
  the prompt and zoxide's once-only guard skips re-wrapping, giving a false negative. Test in a
  single-load shell. (zsh is unaffected — `zoxide init zsh` uses a `chpwd`/`precmd` hook ARRAY,
  not a single wrapped function, so order vs starship/p10k doesn't matter the same way.)
  The profile also `Set-Alias cd __zoxide_z` (+ `cdi`→`__zoxide_zi`) to mirror the zsh
  `alias cd="z"`/`alias cdi="zi"`, so `cd <keyword>` fuzzy-jumps on every platform. `__zoxide_z`
  still cd's literally for real paths (`cd ..`, `cd C:\x`, `cd .\sub`); it only jumps when the
  arg isn't an existing dir. `-Force` is required to override the built-in read-only
  `cd`→Set-Location alias; `-Option AllScope` follows it into nested scopes.
  **The `cd`→zoxide alias is guarded by `CLAUDECODE` on BOTH shells** (`[[ -z "$CLAUDECODE" ]]`
  in zsh, `-not $env:CLAUDECODE` in pwsh): inside Claude Code's tool shell (CLAUDECODE=1) a
  `cd <badpath>` would route through zoxide and leak `zoxide: no match found` into the command's
  piped output, corrupting rtk's JSON rewrites and grep/JSON pipelines. The real `cd` builtin is
  kept there; humans outside Claude still get zoxide jumps. (rtk's hook is NOT the culprit — it
  passes `cd` through untouched; the alias was.)
- **Claude Code statusline: Git Bash flashes a console window on Windows; use the PowerShell
  port.** Claude renders the statusLine on every UI update by launching its `command` as a
  native child (verified: the spawned process has MSYS `PPID=1`, i.e. parented by node, NOT an
  outer `bash -c` — so it's the statusline's own shell). MSYS/Cygwin `bash.exe` calls
  `AllocConsole()` when its stdio is piped, which BYPASSES Node's `windowsHide` flag — so Git
  Bash (and its `jq`/`awk`/`tail` children) flash a console each render, while native console
  apps (pwsh, node, git) spawned the same way stay hidden. Fix: a pure-PowerShell statusline
  (`dot_claude/statusline.ps1`) so Windows launches ONE hidden `pwsh.exe`. `dot_claude/
  executable_statusline.sh` stays the macOS/Linux version; keep the two in sync. They're OS-gated
  in `.chezmoiignore` (`.sh` ignored on Windows, `.ps1` on Unix). **`dot_claude/settings.json`
  is now a PLAIN managed file (no template), so its `statusLine.command` is hardcoded to the
  Unix `bash $HOME/.claude/statusline.sh`** — a plain file can't branch per-OS the way the old
  `modify_settings.json.tmpl` did. On Windows this points at the wrong script; if you apply on
  Windows, override `statusLine` to `pwsh -NoLogo -NoProfile -File <home>/.claude/statusline.ps1`
  machine-locally (or re-introduce a thin per-OS template just for that key).
  Bonus: the bash script's `echo -e` mangles Windows backslash paths (`\0` in `C:\Users\0x130`
  → NUL), so line 1 was already broken on Windows; the PS port fixes it.
- **`~/.claude/settings.json` is a PLAIN managed file (`dot_claude/settings.json`) — chezmoi
  fully owns it, `apply` overwrites the live file.** Replaced the old `modify_settings.json.tmpl`
  merge-template (dropped for simplicity + `czra` round-trip; the template could not be captured
  by `czra`). Tradeoffs of going plain, know them:
  - **`apply` CLOBBERS live machine-local keys.** Claude rewrites settings.json constantly (plugin
    toggles, marketplaces, ad-hoc approved commands) — those edits revert on the next `apply`
    unless captured. To keep a live change, run `czra` (chezmoi re-add) — which now WORKS because
    it's a plain file — then commit. This is the whole reason for the switch: edit live → `czra` →
    push, instead of editing a template by hand.
  - The tracked file holds the curated shared state: `env`, `model`, `defaultMode`, `hooks`
    (rtk), `statusLine` (Unix — see the statusline gotcha above for Windows), `permissions.allow`
    (Bash baseline + codegraph MCP), `enabledPlugins`, `extraKnownMarketplaces`, the booleans.
  - Appears in `chezmoi status`/`czd` and trips the `80-chezmoi-drift.zsh` nudge whenever Claude
    touches it — expected; `czra` to absorb, or `czd` to see what changed.
  - Do NOT switch to symlink mode: Claude saves atomically via rename, replacing any symlink.
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
