# AGENTS.md — PowerShell profile + starship (Windows)

Scoped to `dot_config/powershell/profile.ps1` and `dot_config/starship.toml`. Bootstrap-side
pwsh/WinPS rules are in the root `AGENTS.md`. The "why" behind each rule is in its commit
(`git log -S`).

## Profile
- Edit `dot_config/powershell/profile.ps1`, never `$PROFILE`: the bootstrap dot-sources the
  managed file from BOTH `$PROFILE`s (pwsh 7 and WinPS 5.1).
- **Gate anything newer than PSReadLine 2.0.0** (WinPS 5.1's version; no `-PredictionSource`).
  A side-installed newer module on this box proves nothing about a fresh one.
  - Wrap `-PredictionSource` in `try/catch` (it throws terminating when output is redirected);
    `-ErrorAction SilentlyContinue` does not help.
  - Guard on `Get-Module PSReadLine` (already loaded), not `Import-Module`, so non-interactive
    hosts (Claude's tool shell) skip the block.
  - `InlineView` is the default — only write `ListView`.
- **PSFzf is lazy-loaded** (import costs ~150ms). `Tab`, `Ctrl+t`, `Ctrl+r`, `Alt+c` call
  `Use-PSFzf` and then PSFzf's handler; if the import fails, `Tab`/`Ctrl+r` fall back to
  PSReadLine `Complete`/`ReverseSearchHistory`. The chords live inside the `fzf` guard, and the
  PSReadLine block runs first so the fzf `Tab` bind wins.
- **PSFzf's Tab preview stays hidden** (`-TabCompletionPreviewWindow 'hidden|hidden'`): upstream
  (2.7.12) passes a NUL-delimited line to the preview (`cmd.exe: invalid argument`) and has no
  preview program on pwsh 7. `Ctrl+t` keeps its bat preview.
- **NEVER put `--preview-window` in `FZF_DEFAULT_OPTS`** (it lives in `FZF_CTRL_T_OPTS`): fzf
  merges it into PSFzf's `hidden` and re-opens the broken preview below 90 columns.
- `cd`/`z` have a `-Native` argument completer (local dirs via `CompleteFilename` +
  `zoxide query --list`, zoxide skipped for path-like words); without it `cd ch<Tab>` only sees CWD.
- Removals use `-ErrorAction Ignore` (`SilentlyContinue` still fills `$Error`).
- `powershell` → `pwsh` is a pwsh-7-only alias (version-gated: 5.1 loads this file too). Never
  shim/redirect `powershell.exe` itself — the bootstrap and the komorebi task need real 5.1.

## Load budget: 500ms (currently ~210ms)
- Above 500ms pwsh prints "Loading personal and system profiles took …" intermittently.
- `Get-InitScript` caches generated inits (starship, gh, zoxide) in `~/.cache/pwsh`, keyed by the
  exe's full path (versioned mise dirs = automatic invalidation), written temp-then-rename,
  UTF-8 **with** BOM (5.1 loads it). `rm -r ~/.cache/pwsh` rebuilds. Old caches aren't pruned.
- starship's cached init has its `--continuation` prompt baked in (`-Transform`) and depends on
  `starship.toml`'s mtime; if the pattern stops matching, the spawn just stays.
- **Do NOT cache `mise env`** — a stale PATH silently drops tools, and validating it needs a spawn.
- Measure in a REAL console (`Start-Process pwsh -Wait -ArgumentList '-NoExit','-NoProfile',
  '-File',<harness>`), Stopwatch marks per `# ──` block, median of ~8 runs. Cold runs lie.

## Init order & aliases
- **Aliases resolve before functions**: `Remove-Item Alias:ls -Force` before `function ls`.
  Do the same for any new function whose name is a default alias.
- **Init order gh → starship → zoxide.** starship replaces `prompt`; zoxide wraps it (once), so
  zoxide must come last or no directory is ever recorded. Check:
  `$function:prompt -match '__zoxide_hook'`. Test in a single-load shell — `pwsh -Command` plus
  `. $PROFILE` double-loads and gives a false negative.
- `cd` → `__zoxide_z` alias is skipped under `CLAUDECODE` (root `AGENTS.md`).

## starship
- Theme = `starship preset pure-preset` recolored with a trimmed catppuccin mocha palette. No
  version modules (no `--version` spawns); `python` shows only an active venv.
- `scan_timeout = 500` — a ceiling, not a cost (a cold FS cache blows the 30ms default).
- Inside a git repo ~70ms is fixed repo-discovery cost billed to the first git-aware module;
  moving it saves nothing. `git_status` (~30ms) stays on. The top-level `format` lists modules explicitly —
  a module not in it never runs.
- Measure with `starship timings`, never by guessing.
