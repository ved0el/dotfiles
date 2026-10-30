# Keeps CLAUDE_CODE_GIT_BASH_PATH on scoop's CURRENT git. run_after_ (every `chezmoi apply`), not
# part of run_onchange_10: under no_junction (sshd profile) the path is versioned, so each
# `scoop update git` deletes the old dir and Claude Code falls back to WSL's bash.exe.
# Claude Code runs its shell tool in Git Bash, found from git.exe's location - scoop's git.exe is
# a shim in <scoop>\shims, so that lookup misses bash. Point it there when unset, or when it
# still points into scoop's git at another path (the old `current` junction — unreachable over
# SSH — or a previous version); a path outside scoop is the user's and stays.
# A git from elsewhere (Git for Windows, a CI runner) has no scoop prefix ('' — and both
# Join-Path and Test-Path throw on ''): skip, Claude Code finds that git's bash itself.

# Same WinPS 5.1 PSModulePath reset as run_onchange_10 (pwsh 7's module dirs break 5.1 cmdlets).
$env:PSModulePath = @(
  (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules')
  [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
) -join ';'

# Separate process: part 1's SCOOP / PATH edits are only in User env on a fresh box.
$ScoopDir = [Environment]::GetEnvironmentVariable('SCOOP', 'User')
if (-not $ScoopDir) { exit 0 }
$env:Path = "$(Join-Path $ScoopDir 'shims');$env:Path"
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { exit 0 }

$gitPrefix = "$(scoop prefix git 6>$null)"
$gitBash = if ($gitPrefix) { Join-Path $gitPrefix 'bin\bash.exe' }
$curBash = [Environment]::GetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', 'User')
if ($gitBash -and (Test-Path $gitBash) -and (-not $curBash -or ($curBash -like "$ScoopDir\apps\git\*" -and $curBash -ne $gitBash))) {
  [Environment]::SetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', $gitBash, 'User')
  Write-Host "[git-bash] CLAUDE_CODE_GIT_BASH_PATH -> $gitBash (restart Claude Code)"
}
