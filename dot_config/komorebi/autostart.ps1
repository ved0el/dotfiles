# komorebi autostart launcher — run by the 'komorebi' logon scheduled task.
#
# Why this exists (not `komorebic enable-autostart` / a shell:startup shortcut):
#   komorebic start does `Start-Process komorebi.exe`, which resolves komorebi.exe via PATH.
#   At login the environment (scheduled task, and early explorer startup) does NOT have scoop's
#   shims on PATH, so komorebi.exe is never found and komorebi never launches — nothing tiles.
#   Verified: stripping <scoop>\shims from PATH reproduces the failure exactly; restoring it
#   fixes it. On top of that, the very first start right after login can exit before the shell
#   is ready. So: put scoop's shims on PATH, wait for the session to settle, then start
#   komorebi + whkd and retry until it actually sticks. Idempotent — no-ops once komorebi is up.
#
# Runs under Windows PowerShell 5.1 (launched via System32\powershell.exe, which — unlike the
# scoop-shimmed pwsh — is always on the task's PATH). Keep it 5.1-compatible.
#
# -ShimsDir: scoop's shims directory (holds komorebi.exe), resolved at task-registration time
# when PATH is intact and passed in here. A broken login/task environment can't discover scoop's
# root on its own — scoop can live anywhere (this box uses D:\scoop and doesn't set $env:SCOOP).
param([string]$ShimsDir)

$ErrorActionPreference = 'SilentlyContinue'

# Resolve scoop shims: explicit arg first, then $env:SCOOP, then the default ~/scoop.
if (-not $ShimsDir) {
  $scoop = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE 'scoop' }
  $ShimsDir = Join-Path $scoop 'shims'
}
if ((Test-Path $ShimsDir) -and ($env:Path -notlike "*$ShimsDir*")) { $env:Path = "$ShimsDir;$env:Path" }

$cfg = Join-Path $HOME '.config\komorebi\komorebi.json'

# Let the desktop/environment settle, then (re)start until komorebi is alive. ~10s + 6×8s covers
# the window where an early start would otherwise exit.
Start-Sleep -Seconds 10
for ($i = 0; $i -lt 6; $i++) {
  if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
    komorebic start --whkd --config $cfg | Out-Null
  }
  Start-Sleep -Seconds 8
}

# Re-evaluate all windows against ignore_rules once the desktop has settled. Windows already
# open at login (e.g. a browser session-restoring a Bitwarden extension popup) get managed
# before their title settles, and komorebi does NOT re-check ignore rules on later title
# changes — so a Title-matched popup stays wrongly tiled. Reloading the config forces a
# re-evaluation and drops it to the floating/ignored state it should have had.
if (Get-Process komorebi -ErrorAction SilentlyContinue) {
  Start-Sleep -Seconds 5
  komorebic replace-configuration $cfg | Out-Null
}
