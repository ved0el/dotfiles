# Restore whatever the last psmux-resurrect save has that isn't running; never attaches.
# Called by `tm` (pwsh profile) and, on an `sshd` box, by the `psmux-restore` logon task (with
# autologon that is right after boot, so an SSH login finds the sessions — and their resumed
# Claude conversations — already there). Restore is idempotent: a running session is left
# alone. `psmux ls` exits 0 with no server, so "running" = its output. Restore reads the
# strategy/process options from a live server, hence the throwaway `tm-boot` when there is none.
$dir = Join-Path $HOME '.psmux\resurrect'
$last = Join-Path $dir 'last'
$restore = Join-Path $HOME '.psmux\plugins\psmux-resurrect\scripts\restore.ps1'
if (-not ((Test-Path $last) -and (Test-Path $restore))) { return }

$running = @(psmux ls 2>$null | ForEach-Object { ($_ -split ':')[0] } | Where-Object { $_ })
$saved = @((Get-Content (Get-Content $last -Raw).Trim() -Raw | ConvertFrom-Json).sessions.name)
if (-not ($saved | Where-Object { $_ -notin $running })) { return }

if (-not $running) { psmux new-session -d -s tm-boot }
# The restore's report is kept for debugging (the node strategy logs per pane beside it).
pwsh -NoProfile -File $restore 2>&1 | Tee-Object (Join-Path $dir 'tm-restore.log')
if (-not $running) { psmux kill-session -t tm-boot }
