# AGENTS.md — Windows bootstrap (`run_*.ps1.tmpl` + `.chezmoitemplates/bootstrap-steps.ps1`)

Read before editing a `.ps1` bootstrap or any Windows setup step. The fail-the-script rule and the
pointers (PowerShell profile, WM) are in the root `AGENTS.md`; the "why" is in the commits
(`git log -S`).

- Mechanics of that rule: `Invoke-Step` (`bootstrap-steps.ps1`) runs a step under `Continue` and
  counts a throw or non-zero exit; `Complete-Bootstrap` exits 1 if any failed. README's one-liner
  uses `--keep-going` so a failed part 1 doesn't skip part 2; part 2 stops when part 1 left no mise.
- **Preflight, before changing anything** (part 1): exit on an elevated terminal (scoop's
  installer `break`s out mid-way; `$env:CI` is exempt, as in scoop's own check) and, when pwsh is
  missing, on a winget that isn't ready (new account) — NO scoop-pwsh fallback; the user updates
  App Installer and re-runs.
- Part 1 also sets: CurrentUser `RemoteSigned` for WinPS 5.1 (default Restricted blocks its
  profile + scoop shims) only if unset; `CLAUDE_CODE_GIT_BASH_PATH` → scoop's versioned `bash.exe`
  (Claude can't derive it from the `git.exe` shim) if unset or still pointing into scoop's git
  elsewhere (the old `current` junction fails over SSH) — in `run_after_15-git-bash-path.ps1`
  (every apply: under `no_junction` each `scoop update git` deletes the versioned dir). `bootstrap-steps.ps1`'s `Set-GitHubToken`
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
- **Windows Terminal is not managed** (Alacritty is the terminal). A font a config names must be one
  the bootstrap installs — check the FAMILY NAME the package registers (its manifest's `-Filter`,
  then the .ttf's name table), not just the files it ships: `JetBrainsMono-NF` →
  `JetBrainsMonoNL Nerd Font`, `-NF-Mono` → only `… Nerd Font Mono`.
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
- `powershell.exe` "not recognized" = `System32\WindowsPowerShell\v1.0` fell off PATH; add it to
  the User PATH by hand (not a bootstrap step).
