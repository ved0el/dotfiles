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
# Runs under Windows PowerShell 5.1, launched by the 'komorebi' task as
# `conhost.exe --headless System32\powershell.exe -File <this>` — --headless so no console window
# ever flashes at logon; 5.1 (not the scoop-shimmed pwsh) because pwsh isn't reliably on the task
# PATH. Keep it 5.1-compatible.
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
$komorebiExe  = if ($ShimsDir -and (Test-Path (Join-Path $ShimsDir 'komorebi.exe')))  { Join-Path $ShimsDir 'komorebi.exe' }  else { 'komorebi.exe' }
$whkdExe      = if ($ShimsDir -and (Test-Path (Join-Path $ShimsDir 'whkd.exe')))      { Join-Path $ShimsDir 'whkd.exe' }      else { 'whkd.exe' }
$komorebicExe = if ($ShimsDir -and (Test-Path (Join-Path $ShimsDir 'komorebic.exe'))) { Join-Path $ShimsDir 'komorebic.exe' } else { 'komorebic.exe' }

# Start komorebi ASAP — no up-front wait, fire on the very first iteration. An early start can
# still exit before the shell is ready, so keep (re)starting until it sticks, polling every 1s,
# and break the instant it's alive. Bounded so the task can't loop forever.
for ($i = 0; $i -lt 60; $i++) {
  if (Get-Process komorebi -ErrorAction SilentlyContinue) { break }
  Start-Process $komorebiExe -ArgumentList "--config `"$cfg`"" -WindowStyle Hidden
  Start-Sleep -Seconds 1
}
# whkd (hotkeys) — start hidden if not already running.
if (-not (Get-Process whkd -ErrorAction SilentlyContinue)) {
  Start-Process $whkdExe -WindowStyle Hidden
}

# Reload the config as soon as komorebi is RESPONSIVE (not after a guessed sleep) so ignore_rules
# get re-applied to windows that were already open at login. Needed because komorebi can manage a
# window before its title settles — e.g. the Bitwarden browser popup, whose ignore rule matches on
# Title — and it does not re-check ignore_rules on later title changes. `komorebic state` only
# succeeds once komorebi's socket is serving, which is exactly when a reload can land.
for ($i = 0; $i -lt 60; $i++) {
  & $komorebicExe state *>$null
  if ($LASTEXITCODE -eq 0) {
    & $komorebicExe replace-configuration $cfg *>$null
    break
  }
  Start-Sleep -Seconds 1
}
