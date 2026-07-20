# komorebi autostart launcher — run by the 'komorebi' logon scheduled task.
#
# Why this exists (not `komorebic enable-autostart` / a shell:startup shortcut):
#   At login the environment (scheduled task, early explorer startup) has NO scoop shims on PATH,
#   so komorebi.exe can't be found and komorebi never launches — nothing tiles (verified: strip
#   <scoop>\shims from PATH → reproduces). And an early start can exit before the shell is ready.
#   So: resolve the shims dir, launch komorebi.exe + whkd.exe directly (hidden), retrying until it
#   sticks. Direct launch — NOT `komorebic start` — because komorebic start spawns a pwsh process
#   for its launch sequence that flashes a visible console window at login. Idempotent.
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

# Launch komorebi.exe / whkd.exe DIRECTLY (hidden) instead of `komorebic start`: komorebic start
# spawns a PowerShell process to run its launch sequence, and with scoop's shims now on PATH it
# picks pwsh (Core) — flashing a visible console window at login. Full shim paths so we never
# depend on PATH resolution. komorebi.exe reads the same static config via -c.
$komorebiExe = if ($ShimsDir -and (Test-Path (Join-Path $ShimsDir 'komorebi.exe'))) { Join-Path $ShimsDir 'komorebi.exe' } else { 'komorebi.exe' }
$whkdExe     = if ($ShimsDir -and (Test-Path (Join-Path $ShimsDir 'whkd.exe')))     { Join-Path $ShimsDir 'whkd.exe' }     else { 'whkd.exe' }

# Start komorebi as soon as the session allows — no long up-front wait. An early start can exit
# before the shell is ready, so keep (re)starting until it sticks, polling every 2s, and break
# the instant it's alive. Bounded so the task can't loop forever.
for ($i = 0; $i -lt 40; $i++) {
  if (Get-Process komorebi -ErrorAction SilentlyContinue) { break }
  Start-Process $komorebiExe -ArgumentList "--config `"$cfg`"" -WindowStyle Hidden
  Start-Sleep -Seconds 2
}
# whkd (hotkeys) — start hidden if not already running.
if (-not (Get-Process whkd -ErrorAction SilentlyContinue)) {
  Start-Process $whkdExe -WindowStyle Hidden
}

# brave.exe is in object_name_change_applications, so komorebi re-evaluates its windows when the
# title settles — the Bitwarden extension popup lands ignored on its own. One reload after a
# short settle is a safety net for windows already open when komorebi first started.
if (Get-Process komorebi -ErrorAction SilentlyContinue) {
  Start-Sleep -Seconds 8
  komorebic replace-configuration $cfg | Out-Null
}
