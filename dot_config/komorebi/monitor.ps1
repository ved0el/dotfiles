# whkd: focus (or, with -Move, take the focused window to) the monitor to the LEFT/RIGHT of the
# focused one, by screen position. komorebic's cycle-monitor follows monitor INDEX order, which is
# Windows' enumeration order, not left-to-right, and wraps; pinning the order
# (display_index_preferences) is per-machine, so it was dropped. Works for any count/arrangement.
# shortcut: left/right only (a monitor stacked above/below is never picked), add up/down if one is.
param([ValidateSet('left', 'right', 'test')][string]$Direction, [switch]$Move)

# Index of the nearest monitor (by centre x) strictly on that side of monitor $from, or -1.
function Get-Neighbour($sizes, [int]$from, [string]$dir) {
  $cx = { param($r) $r.left + $r.right / 2 }   # komorebi's size: right = width
  $x0 = & $cx $sizes[$from]; $best = -1; $bestDist = [double]::MaxValue
  for ($i = 0; $i -lt $sizes.Count; $i++) {
    $d = (& $cx $sizes[$i]) - $x0
    if ($dir -eq 'left') { $d = -$d }
    if ($d -gt 0 -and $d -lt $bestDist) { $best = $i; $bestDist = $d }
  }
  $best
}

if ($Direction -eq 'test') {
  # Three in a row, enumerated out of order: [middle, left, right].
  $r = @(@{left = 0; right = 3440 }, @{left = -2560; right = 2560 }, @{left = 3440; right = 1920 })
  $cases = @((0, 'left', 1), (0, 'right', 2), (1, 'right', 0), (2, 'left', 0), (1, 'left', -1), (2, 'right', -1))
  foreach ($c in $cases) {
    $got = Get-Neighbour $r $c[0] $c[1]
    if ($got -ne $c[2]) { throw "from $($c[0]) $($c[1]): want $($c[2]) got $got" }
  }
  'ok'; return
}

$state = komorebic state | ConvertFrom-Json
$target = Get-Neighbour @($state.monitors.elements.size) $state.monitors.focused $Direction
if ($target -lt 0) { return }   # already the outermost monitor on that side
if ($Move) { komorebic move-to-monitor $target } else { komorebic focus-monitor $target }
