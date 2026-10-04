# psmux-resurrect restore strategy for `node` panes (@resurrect-strategy-node 'claude').
# psmux saves a Claude Code pane as the bare command `node`, so a plain restore starts a node
# REPL. This resumes the pane's Claude conversation instead: the saved pane title is Claude's
# terminal title ("✳ <name>"), and <name> is the `custom-title` record in the conversation's
# ~/.claude/projects/<cwd>/<id>.jsonl. Anything not matched to exactly one conversation (no
# title, a non-Claude node, two node panes in one dir) gets a comment line: the pane opens in
# its directory and runs nothing. Never print nothing — resurrect then falls back to `node`.
param(
    [Parameter(Mandatory)] [string] $OriginalCommand,
    [Parameter(Mandatory)] [string] $Directory
)
$noop = '# psmux-resurrect: node not restored'
# One line per decision, to debug a restore after the fact.
$log = Join-Path $HOME '.psmux\resurrect\strategy.log'
function Out-Decision([string]$cmd, [string]$why) {
    Add-Content $log "$(Get-Date -Format s) [$Directory] $why -> $cmd" -ErrorAction Ignore
    $cmd
}
try {
    # The strategy contract passes no pane title; recover it from the save being restored.
    $save = (Get-Content (Join-Path $HOME '.psmux\resurrect\last') -Raw).Trim()
    $panes = @((Get-Content $save -Raw | ConvertFrom-Json).sessions.windows.panes |
        Where-Object { $_.directory -eq $Directory -and $_.command -eq 'node' })
    if ($panes.Count -ne 1) { return Out-Decision $noop "$($panes.Count) node panes in this dir" }
    # Strip Claude's status glyph ("✳ ", a spinner) in front of the name.
    $title = $panes[0].title -replace '^[^\p{L}\p{N}]+\s+', ''
    if (-not $title) { return Out-Decision $noop 'no pane title' }

    $projDir = Join-Path $HOME ('.claude\projects\' + ($Directory -replace '[^A-Za-z0-9]', '-'))
    $hits = @(Get-ChildItem $projDir -Filter *.jsonl -ErrorAction Stop |
        Where-Object { Select-String -Path $_.FullName -SimpleMatch "`"customTitle`":`"$title`"" -Quiet })
    if ($hits.Count -ne 1) { return Out-Decision $noop "title '$title': $($hits.Count) conversations" }
    # cd first: a warm (pre-booted) pane is moved to its dir by psmux typing `cd ...; cls`,
    # which these keys could race — claude in ~ would resume nothing.
    Out-Decision "Set-Location -LiteralPath '$($Directory -replace "'", "''")'; claude --resume $($hits[0].BaseName)" "title '$title'"
} catch { Out-Decision $noop "error: $_" }
