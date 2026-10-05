# psmux-resurrect restore strategy for `node` panes (@resurrect-strategy-node 'claude').
# psmux saves a Claude Code pane as the bare command `node`, so a plain restore starts a node
# REPL. This resumes the pane's Claude conversation instead, found by the pane's directory:
#   1. ~/.psmux/claude-sessions/<dir> — the session id Claude's statusline (statusline.ps1)
#      records while it runs inside psmux;
#   2. else (saves from before that record) the saved pane title, when it is Claude's own
#      ("✳ <name>") and <name> is one conversation's `custom-title` record.
# Anything not matched (a non-Claude node, two node panes in one dir) gets a comment line: the
# pane opens in its directory and runs nothing. Never print nothing — resurrect then falls
# back to `node`.
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
# cd first: a warm (pre-booted) pane is moved to its dir by psmux typing `cd ...; cls`,
# which these keys could race — claude in ~ would resume nothing.
function Resume([string]$id) { "Set-Location -LiteralPath '$($Directory -replace "'", "''")'; claude --resume $id" }
try {
    # The strategy contract passes only the dir; read the pane from the save being restored.
    $save = (Get-Content (Join-Path $HOME '.psmux\resurrect\last') -Raw).Trim()
    $panes = @((Get-Content $save -Raw | ConvertFrom-Json).sessions.windows.panes |
        Where-Object { $_.directory -eq $Directory -and $_.command -eq 'node' })
    if ($panes.Count -ne 1) { return Out-Decision $noop "$($panes.Count) node panes in this dir" }

    $projDir = Join-Path $HOME ('.claude\projects\' + ($Directory -replace '[^A-Za-z0-9]', '-'))
    $map = Join-Path $HOME ('.psmux\claude-sessions\' + ($Directory.ToLower() -replace '[^a-z0-9]', '-'))
    if (Test-Path -LiteralPath $map) {
        $id = (Get-Content -LiteralPath $map -Raw).Trim()
        if ($id -and (Test-Path -LiteralPath (Join-Path $projDir "$id.jsonl"))) { return Out-Decision (Resume $id) 'recorded session' }
    }

    # Older saves: Claude's own title. Strip its status glyph ("✳ ", a spinner) first.
    $title = $panes[0].title -replace '^[^\p{L}\p{N}]+\s+', ''
    if (-not $title) { return Out-Decision $noop 'no record, no pane title' }
    $hits = @(Get-ChildItem $projDir -Filter *.jsonl -ErrorAction Stop |
        Where-Object { Select-String -Path $_.FullName -SimpleMatch "`"customTitle`":`"$title`"" -Quiet })
    if ($hits.Count -ne 1) { return Out-Decision $noop "no record; title '$title': $($hits.Count) conversations" }
    Out-Decision (Resume $hits[0].BaseName) "title '$title'"
} catch { Out-Decision $noop "error: $_" }
