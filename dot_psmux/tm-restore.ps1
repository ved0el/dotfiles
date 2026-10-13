# Restore whatever the last psmux-resurrect save has that isn't running; never attaches.
# Called by `tm` (pwsh profile) and, on an `sshd` box, by the `psmux-restore` logon task (with
# autologon that is right after boot, so an SSH login finds the sessions — and their resumed
# Claude conversations — already there). Restore is idempotent: a running session is left
# alone. `psmux ls` exits 0 with no server, so "running" = its output. Restore reads the
# strategy/process options from a live server, hence the throwaway `tm-boot` when there is none.
$dir = Join-Path $HOME '.psmux\resurrect'
$last = Join-Path $dir 'last'
$restore = Join-Path $HOME '.psmux\plugins\psmux-resurrect\scripts\restore.ps1'
# Only right after boot (the logon task), so an interactive `tm` never hangs on a closed Beeper
# and never locks the screen.
$justBooted = [Environment]::TickCount64 -lt 300000

try {
  if (-not ((Test-Path $last) -and (Test-Path $restore))) { return }

  $running = @(psmux ls 2>$null | ForEach-Object { ($_ -split ':')[0] } | Where-Object { $_ })
  $save = Get-Content (Get-Content $last -Raw).Trim() -Raw | ConvertFrom-Json
  $todo = @($save.sessions | Where-Object { $_.name -notin $running })
  if (-not $todo) { return }

  # Resumed Claude panes connect their MCP servers once, at start. Right after logon Beeper
  # Desktop (whose MCP is http://127.0.0.1:23373) comes up ~20s after this task fires, so wait
  # for its port, or Claude starts with beeper failed until a manual /mcp reconnect.
  # ponytail: Beeper only; add other local MCP ports here if one shows the same race.
  if ($justBooted -and (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name com.automattic.beeper.desktop -EA SilentlyContinue)) {
    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
      $c = [Net.Sockets.TcpClient]::new()
      try { $c.Connect('127.0.0.1', 23373); break } catch { Start-Sleep -Milliseconds 500 } finally { $c.Dispose() }
    }
  }

  if (-not $running) { psmux new-session -d -s tm-boot }
  $started = Get-Date
  # The restore's report is kept for debugging (the node strategy logs per pane beside it).
  pwsh -NoProfile -File $restore 2>&1 | Tee-Object (Join-Path $dir 'tm-restore.log')
  if (-not $running) { psmux kill-session -t tm-boot }

  # Claude panes the node strategy missed: psmux saves a pane's FOREGROUND process, so a Claude
  # busy in a tool at save time (its pwsh child) is saved as `pwsh` and never reaches the
  # strategy. ~/.psmux/claude-sessions/<dir> (statusline.ps1) is deleted when a conversation is
  # exited (statusline.ps1 -SessionEnd hook), so a record still there = a conversation alive at
  # shutdown: resume it in the first restored non-node pane of that dir, unless the strategy did.
  $mapDir = Join-Path $HOME '.psmux\claude-sessions'
  $stratLog = Join-Path $dir 'strategy.log'
  $done = @(if (Test-Path $stratLog) {
    Get-Content $stratLog | Where-Object { $_ -match '^(\S+) ' -and [datetime]$Matches[1] -ge $started.AddSeconds(-1) }
  })
  $claimed = @{}
  foreach ($s in $todo) { foreach ($w in $s.windows) { foreach ($p in $w.panes) {
    if ($p.command -eq 'node' -or -not $p.directory) { continue }
    $key = $p.directory.ToLower() -replace '[^a-z0-9]', '-'
    $map = Join-Path $mapDir $key
    if ($claimed[$key] -or -not (Test-Path -LiteralPath $map)) { continue }
    $claimed[$key] = $true
    $id = (Get-Content -LiteralPath $map -Raw).Trim()
    if (-not $id -or ($done -match [regex]::Escape($id))) { continue }
    # psmux resolves `s:w.<index>` for no pane, only `s:w.%<id>` (ids are per session server).
    $paneId = (psmux list-panes -t "$($s.name):$($w.index)" -F '#{pane_index} #{pane_id}' 2>$null |
        Where-Object { $_ -match "^$($p.index) " }) -replace '^\d+ ', ''
    if (-not $paneId) { continue }
    $target = "$($s.name):$($w.index).$paneId"
    $cmd = "Set-Location -LiteralPath '$($p.directory -replace "'", "''")'; claude --resume $id --remote-control"
    psmux send-keys -t $target $cmd Enter
    Add-Content $stratLog "$(Get-Date -Format s) [$($p.directory)] fallback ($($p.command) pane $target) -> $cmd" -ErrorAction Ignore
  } } }
} finally {
  # Autologon leaves the console signed in: lock it once the sessions are back. A locked
  # session keeps every app (and the resumed Claude panes) running; SSH/RDP/Remote Control work.
  if ($justBooted) { rundll32.exe user32.dll,LockWorkStation }
}
