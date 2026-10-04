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
try {
    # The strategy contract passes no pane title; recover it from the save being restored.
    $save = (Get-Content (Join-Path $HOME '.psmux\resurrect\last') -Raw).Trim()
    $panes = @((Get-Content $save -Raw | ConvertFrom-Json).sessions.windows.panes |
        Where-Object { $_.directory -eq $Directory -and $_.command -eq 'node' })
    if ($panes.Count -ne 1) { return $noop }
    # Strip Claude's status glyph ("✳ ", a spinner) in front of the name.
    $title = $panes[0].title -replace '^[^\p{L}\p{N}]+\s+', ''
    if (-not $title) { return $noop }

    $projDir = Join-Path $HOME ('.claude\projects\' + ($Directory -replace '[^A-Za-z0-9]', '-'))
    $hits = @(Get-ChildItem $projDir -Filter *.jsonl -ErrorAction Stop |
        Where-Object { Select-String -Path $_.FullName -SimpleMatch "`"customTitle`":`"$title`"" -Quiet })
    if ($hits.Count -ne 1) { return $noop }
    # cd first: a restored pane is a pre-booted (warm) shell that psmux moves into the pane's
    # dir by typing a `cd`, which these keys can beat — claude then starts in ~ (trust prompt).
    "Set-Location -LiteralPath '$($Directory -replace "'", "''")'; claude --resume $($hits[0].BaseName)"
} catch { $noop }
