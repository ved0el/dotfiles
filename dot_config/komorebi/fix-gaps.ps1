# whkd alt+ctrl+r: drop "ghost" tiles, then retile. komorebi sometimes misses an app's minimize /
# close-to-tray event and keeps its tile (an empty gap); retile and restart don't drop it (a restart
# even re-adopts minimized windows). Showing the window and minimizing it again sends komorebi a
# real Show + Minimize pair, which it handles. Only the focused workspace of each monitor: windows
# on the others are cloaked by komorebi (window_hiding_behaviour Cloak), so they still read visible.
Add-Type -Namespace Komorebi -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
'@
$state = komorebic state | ConvertFrom-Json
foreach ($monitor in $state.monitors.elements) {
  $ws = $monitor.workspaces.elements[$monitor.workspaces.focused]
  foreach ($w in @($ws.containers.elements | ForEach-Object { $_.windows.elements })) {
    $h = [IntPtr][long]$w.hwnd
    if ([Komorebi.Win]::IsIconic($h) -or -not [Komorebi.Win]::IsWindowVisible($h)) {
      [void][Komorebi.Win]::ShowWindow($h, 4)   # SW_SHOWNOACTIVATE
      Start-Sleep -Milliseconds 300             # let komorebi process the Show first
      [void][Komorebi.Win]::ShowWindow($h, 7)   # SW_SHOWMINNOACTIVE -> komorebi drops the tile
    }
  }
}
komorebic retile
