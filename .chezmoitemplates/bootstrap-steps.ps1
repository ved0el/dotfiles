# --- shared by both Windows bootstrap parts (.chezmoitemplates/bootstrap-steps.ps1) ---

# TLS 1.2 for irm: WinPS 5.1 on older Windows 10 builds still offers TLS 1.0 by default, which
# get.scoop.sh / GitHub / claude.ai refuse.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# A failed step must FAIL THE SCRIPT. chezmoi records a run_onchange script as done only when it
# exits 0, and never re-runs a recorded one until its content changes - a swallowed network blip
# would leave that tool missing for good. So each step runs through Invoke-Step, and
# Complete-Bootstrap exits 1 if any failed; every step is idempotent, so the next
# `chezmoi apply` retries only what's missing.
# Steps run under 'Continue': scoop, winget and git are written for it, and under 'Stop' an
# incidental non-terminating error inside them would abort the whole bootstrap. A throw or a
# non-zero exit code is the failure signal.
$script:Failed = [System.Collections.Generic.List[string]]::new()
function Invoke-Step([string]$Name, [scriptblock]$Block, [string]$Hint) {
  $ok = & {
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    try { & $Block | Out-Host; $global:LASTEXITCODE -eq 0 }
    catch { Write-Host "[$Name] $($_.Exception.Message)"; $false }
  }
  if (-not $ok) {
    $script:Failed.Add($Name)
    Write-Host "[$Name] FAILED$(if ($Hint) { " - $Hint" })" -ForegroundColor Red
  }
}
function Complete-Bootstrap([string]$Part) {
  if ($script:Failed.Count) {
    Write-Host "`n[$Part] failed: $($script:Failed -join ', '). Fix the cause above, then run 'chezmoi apply' - only what's missing re-runs." -ForegroundColor Red
    exit 1
  }
}

# mise resolves github:/aqua: tools through the GitHub API: 60 requests/hour unauthenticated, easy
# to hit on a fresh box (shared IP, a re-run). A logged-in gh (scoop, part 1) lifts it to 5000.
if (-not $env:GITHUB_TOKEN -and (Get-Command gh -ErrorAction SilentlyContinue)) {
  $ghToken = & { $ErrorActionPreference = 'Continue'; gh auth token 2>$null }
  if ($LASTEXITCODE -eq 0 -and $ghToken) { $env:GITHUB_TOKEN = "$ghToken".Trim() }
}
$GhHint = 'GitHub rate limit? run: gh auth login - then chezmoi apply'
