#Requires -Version 7.0
# =============================================================================
# Claude Code 3-line statusline — Windows-native port of statusline.sh.
# =============================================================================
# Pure PowerShell (no MSYS bash / jq / awk). Claude launches ONE native pwsh
# process per render, so no Git Bash console window flashes on Windows. The bash
# version (statusline.sh) stays the source of truth on macOS/Linux; keep the two
# in sync. See the "statusline flash" gotcha in CLAUDE.md.
#
# Line 1  WHERE:    📁 cwd  🔀 branch[✱] [↑↓]  +adds −dels  🌳 worktree
# Line 2  ENGINE:   🤖 model  🎚️ effort  🎯 cache-hit%  🧠 used%
# Line 3  STATUS:   💵 cost  ⏱️ duration  🚦 5h X% (14:50)  🚦 7d Y% (Mon 09:05)  👤 agent
# =============================================================================

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# --- Read + parse the statusline JSON payload from stdin ----------------------
$raw = [Console]::In.ReadToEnd()
try { $J = $raw | ConvertFrom-Json } catch { exit 0 }

# --- Extract (official schema; missing props read back as $null) --------------
$MODEL    = $J.model.display_name
$DIR      = if ($J.workspace.current_dir) { $J.workspace.current_dir } else { $J.cwd }
$AGENT    = $J.agent.name
$WORKTREE = if ($J.worktree.name) { $J.worktree.name } else { $J.workspace.git_worktree }

$EFFORT = $J.effort.level
if (-not $EFFORT) {
    $settings = Join-Path $HOME '.claude\settings.json'
    if (Test-Path $settings) {
        try { $EFFORT = (Get-Content $settings -Raw | ConvertFrom-Json).effortLevel } catch {}
    }
}

$COST     = [double]($J.cost.total_cost_usd ?? 0)
$DUR_MS   = [double]($J.cost.total_duration_ms ?? 0)
$PCT_USED = [int][math]::Floor([double]($J.context_window.used_percentage ?? 0))

# Cache hit rate — summed from the transcript JSONL (the payload exposes no
# per-token cache counters). hit% = cache_read / (cache_read + input + cache_create).
# Cap at the last 2000 lines and pre-filter to assistant-usage rows for speed.
$CACHE_HIT = $null
$TRANSCRIPT = $J.transcript_path
if ($TRANSCRIPT -and (Test-Path -LiteralPath $TRANSCRIPT)) {
    [long]$cr = 0; [long]$inp = 0; [long]$cc = 0
    Get-Content -LiteralPath $TRANSCRIPT -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_ -like '*"usage"*' -and $_ -like '*assistant*') {
            try {
                $o = $_ | ConvertFrom-Json
                if ($o.type -eq 'assistant' -and $o.message.usage) {
                    $u = $o.message.usage
                    $cr  += [long]($u.cache_read_input_tokens     ?? 0)
                    $inp += [long]($u.input_tokens                ?? 0)
                    $cc  += [long]($u.cache_creation_input_tokens ?? 0)
                }
            } catch {}
        }
    }
    $denom = $cr + $inp + $cc
    if ($cr -gt 0 -and $denom -gt 0) { $CACHE_HIT = [int]($cr * 100 / $denom) }
}

$RL5_PCT = $J.rate_limits.five_hour.used_percentage
$RL5_RST = $J.rate_limits.five_hour.resets_at
$RL7_PCT = $J.rate_limits.seven_day.used_percentage
$RL7_RST = $J.rate_limits.seven_day.resets_at

# --- Colors ------------------------------------------------------------------
$e = [char]27
$C = "$e[36m"; $M = "$e[35m"; $G = "$e[32m"; $Y = "$e[33m"; $R = "$e[31m"
$K = "$e[90m"; $W = "$e[1m"; $D = "$e[2m"; $X = "$e[0m"
$BR = "$e[1;31m"; $BY = "$e[1;33m"; $BM = "$e[1;35m"; $BC = "$e[1;36m"

# --- Icons (swap to taste; keep in sync with statusline.sh) -------------------
$ICON_DIR = "📁"; $ICON_GIT = "🔀"; $ICON_MODEL = "🤖"; $ICON_EFFORT = "🎚️"
$ICON_CACHE = "🎯"; $ICON_CTX = "🧠"; $ICON_COST = "💵"; $ICON_TIME = "⏱️"
$ICON_LIMIT = "🚦"; $ICON_AGENT = "👤"; $ICON_TREE = "🌳"

# --- Helpers -----------------------------------------------------------------
function Pct-Color([int]$v, [int]$hi, [int]$mid) {
    if ($v -ge $hi) { $R } elseif ($v -ge $mid) { $Y } else { $G }
}

function Short-Path([string]$p) {
    if (-not $p) { return '' }
    if ($p.ToLower().StartsWith($HOME.ToLower())) { $p = '~' + $p.Substring($HOME.Length) }
    $p = $p -replace '\\', '/'
    if (([regex]::Matches($p, '/')).Count -gt 3) {
        $parts = $p.Split('/'); $n = $parts.Count
        $p = '…/' + $parts[$n - 3] + '/' + $parts[$n - 2] + '/' + $parts[$n - 1]
    }
    return $p
}

# Epoch (s/ms) or ISO-8601 -> "14:50" if today, else "Mon 09:05".
function Fmt-Reset($ts) {
    if (-not $ts) { return '' }
    $s = "$ts"; $dt = $null
    if ($s -match '^\d{10}$') { $dt = [DateTimeOffset]::FromUnixTimeSeconds([long]$s).LocalDateTime }
    elseif ($s -match '^\d{13}$') { $dt = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$s).LocalDateTime }
    else {
        try {
            $dt = [datetimeoffset]::Parse($s, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AssumeUniversal).LocalDateTime
        } catch { return '' }
    }
    if (-not $dt) { return '' }
    $inv = [Globalization.CultureInfo]::InvariantCulture
    if ($dt.Date -eq (Get-Date).Date) {
        return $dt.ToString('HH:mm', $inv)
    }
    return $dt.ToString('ddd HH:mm', $inv)
}

function Fmt-Rl([string]$label, $pct, $reset) {
    if ($null -eq $pct -or "$pct" -eq '') { return '' }
    $p = [int][math]::Round([double]$pct)
    $out = "$ICON_LIMIT $(Pct-Color $p 80 50)$label $p%$X"
    $rs = Fmt-Reset $reset
    if ($rs) { $out += " $K($rs)$X" }
    return $out
}

# --- Effort color ------------------------------------------------------------
$EFFORT_C = switch ($EFFORT) {
    'high'   { $R } 'medium' { $Y } 'low' { $G } default { $D }
}

# --- Git ---------------------------------------------------------------------
$GIT_PART = ''; $EDITS = ''
if ($DIR -and (Get-Command git -ErrorAction SilentlyContinue)) {
    git -C $DIR rev-parse --git-dir 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $branch = git -C $DIR branch --show-current 2>$null
        if (-not $branch) { $branch = git -C $DIR rev-parse --short HEAD 2>$null }
        $dirty = ''
        if (git -C $DIR status --porcelain 2>$null) { $dirty = "$R✱$X" }
        $ab = ''
        $abRaw = git -C $DIR rev-list --left-right --count '@{u}...HEAD' 2>$null
        if ($abRaw) {
            $f = $abRaw -split '\s+'
            if ($f[1] -and $f[1] -ne '0') { $ab += " $Y↑$($f[1])$X" }
            if ($f[0] -and $f[0] -ne '0') { $ab += " $Y↓$($f[0])$X" }
        }
        $GIT_PART = " $M$ICON_GIT $branch$X$dirty$ab"

        $stat = git -C $DIR diff HEAD --shortstat 2>$null
        if ($stat) {
            $fc = if ($stat -match '(\d+) files? changed') { [int]$Matches[1] } else { 0 }
            $ad = if ($stat -match '(\d+) insertions?\(\+\)') { [int]$Matches[1] } else { 0 }
            $de = if ($stat -match '(\d+) deletions?\(-\)') { [int]$Matches[1] } else { 0 }
            if ($fc -gt 0) {
                $EDITS = "$K${fc}f$X"
                if ($ad -gt 0) { $EDITS += " $G+$ad$X" }
                if ($de -gt 0) { $EDITS += " $R−$de$X" }
            }
        }
    }
}

# --- Duration ----------------------------------------------------------------
$DUR = ''
if ($DUR_MS -gt 0) {
    $mins = [int][math]::Floor($DUR_MS / 60000)
    $secs = [int][math]::Floor(($DUR_MS % 60000) / 1000)
    if ($mins -ge 60) { $DUR = "$([int][math]::Floor($mins / 60))h$($mins % 60)m" }
    elseif ($mins -gt 0) { $DUR = "${mins}m" }
    else { $DUR = "${secs}s" }
}

# --- Cost --------------------------------------------------------------------
$COST_FMT = '{0:F2}' -f $COST
$COST_C = if ([math]::Round($COST) -ge 5) { $BR } else { $BY }

# --- LINE 1: WHERE -----------------------------------------------------------
$LINE1 = "$C$ICON_DIR $(Short-Path $DIR)$X$GIT_PART"
if ($EDITS)    { $LINE1 += " $EDITS" }
if ($WORKTREE) { $LINE1 += " $BM$ICON_TREE $WORKTREE$X" }

# --- LINE 2: ENGINE (model · effort · cache · ctx) ---------------------------
$LINE2 = "$BC$ICON_MODEL $MODEL$X"
if ($EFFORT) { $LINE2 += " $ICON_EFFORT $EFFORT_C$EFFORT$X" }
if ($null -ne $CACHE_HIT) {
    # High hit rate is good — invert thresholds so green = ≥80%.
    $cacheC = if ($CACHE_HIT -ge 80) { $G } elseif ($CACHE_HIT -ge 50) { $Y } else { $R }
    $LINE2 += " $ICON_CACHE $cacheC$CACHE_HIT%$X"
}
$LINE2 += " $ICON_CTX $(Pct-Color $PCT_USED 70 40)$W$PCT_USED%$X"

# --- LINE 3: STATUS (cost · duration · rate limits · agent) ------------------
$LINE3 = ''
if ($COST_FMT -ne '0.00') { $LINE3 += "$COST_C$ICON_COST `$$COST_FMT$X" }
if ($DUR) { if ($LINE3) { $LINE3 += ' ' }; $LINE3 += "$K$ICON_TIME $DUR$X" }
$RL5 = Fmt-Rl '5h' $RL5_PCT $RL5_RST
$RL7 = Fmt-Rl '7d' $RL7_PCT $RL7_RST
if ($RL5)   { if ($LINE3) { $LINE3 += ' ' }; $LINE3 += $RL5 }
if ($RL7)   { if ($LINE3) { $LINE3 += ' ' }; $LINE3 += $RL7 }
if ($AGENT) { if ($LINE3) { $LINE3 += ' ' }; $LINE3 += "$BY$ICON_AGENT $AGENT$X" }

# --- Emit (LF line endings, UTF-8) -------------------------------------------
[Console]::Out.Write($LINE1 + "`n")
[Console]::Out.Write($LINE2 + "`n")
if ($LINE3) { [Console]::Out.Write($LINE3 + "`n") }
exit 0
