# AGENTS.md — PowerShell profile + starship (Windows)

Scoped notes for `dot_config/powershell/profile.ps1` and `dot_config/starship.toml`. The bootstrap-side pwsh/WinPS rules (winget pwsh, PSModulePath reset, installing modules through pwsh) stay in the root `AGENTS.md`.

## Profile
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

## Init order & aliases
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

## starship
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
