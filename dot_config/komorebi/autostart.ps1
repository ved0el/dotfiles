# komorebi (re)start helper. Login autostart is komorebi's own `enable-autostart` shortcut
# (komorebic-no-console.exe, set up by bootstrap part 1); this script is the `-Restart` path for
# whkd's alt+ctrl+o and yasb's reload_command, run by System32 powershell.exe (5.1 — keep it
# 5.1-compatible). It launches komorebi.exe + whkd.exe directly (hidden) with retry — NOT
# `komorebic start`, which spawns a pwsh that flashes a console.
#
# -ShimsDir: scoop's shims directory (holds komorebi.exe); optional — falls back to $env:SCOOP,
# then ~/scoop.
#
# -Restart: stop komorebi + whkd first, then run the normal start sequence (whkd's alt+ctrl+o and
# yasb's reload_command). Must run as its OWN process: `komorebic stop --whkd` kills whkd, and a
# `stop; start` chain run inside whkd's shell dies with it before `start` ever runs.
param([string]$ShimsDir, [switch]$Restart)

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

if ($Restart) {
  & $komorebicExe stop --whkd *>$null
  # Wait for both to exit, or the loop below sees the dying komorebi and never starts a new one.
  for ($i = 0; $i -lt 20 -and (Get-Process komorebi, whkd -ErrorAction SilentlyContinue); $i++) {
    Start-Sleep -Milliseconds 500
  }
}

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

# Reload the config as soon as komorebi is RESPONSIVE (not after a guessed sleep) so the rules get
# applied to windows that were ALREADY OPEN at login — komorebi can adopt those before it has read
# the config. `komorebic state` only succeeds once komorebi's socket is serving, which is exactly
# when a reload can land.
# NOTE: this does NOT help a window opened later in the session. An earlier revision of this
# comment claimed it fixed the Bitwarden browser popup; it never could — that popup is created
# minutes after logon. See dot_config/komorebi/AGENTS.md "browser extension popups" for the actual cause and fix.
for ($i = 0; $i -lt 60; $i++) {
  & $komorebicExe state *>$null
  if ($LASTEXITCODE -eq 0) {
    & $komorebicExe replace-configuration $cfg *>$null
    break
  }
  Start-Sleep -Seconds 1
}
