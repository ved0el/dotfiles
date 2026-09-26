# PowerShell profile — Windows analogue of ~/.zshrc + ~/.config/zsh/conf.d/*.
# Dot-sourced from the real $PROFILE by the chezmoi bootstrap (OneDrive-proof).
# Each block self-gates on Get-Command so a tool absent from PATH silently no-ops,
# mirroring the `command -v` guards in the zsh config.

# ── environment ─────────────────────────────────────────────────────────────────
# Keep ~/.local/bin (chezmoi + self-installed tools) on PATH for the session.
$LocalBin = Join-Path $HOME '.local\bin'
if ($env:Path -notlike "*$LocalBin*") { $env:Path = "$LocalBin;$env:Path" }
# XDG_CONFIG_HOME so mise/zoxide/etc. read ~/.config (the same tree as macOS/Linux).
if (-not $env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME = Join-Path $HOME '.config' }
# Actively CLEAR MISE_GLOBAL_CONFIG_FILE / MISE_CONFIG_DIR (never set them). mise's default
# global config is already ~/.config/mise/config.toml (chezmoi-ignored, so `mise use -g` pins
# stay untracked there). Setting MISE_GLOBAL_CONFIG_FILE is redundant AND makes mise stop
# auto-discovering the global config DIRECTORY (the conf.d/*.toml tool manifests) whenever the
# shell's CWD is outside $HOME (e.g. a terminal whose start directory is a drive root) —
# `mise ls` then shows no tools. We unset rather than just skip so a shell launched from a
# parent that still carries a stale value (an older session, before the persisted User var was
# cleared) self-heals.
Remove-Item env:MISE_GLOBAL_CONFIG_FILE -ErrorAction Ignore  # Ignore: no $Error record per launch
Remove-Item env:MISE_CONFIG_DIR -ErrorAction Ignore
# WM config homes (wm profile): komorebi/whkd/yasb read ~/.config/<tool>. komorebi
# defaults to ~/komorebi.json and whkd to ~/.config/whkdrc, so these are needed. The
# bootstrap persists them (User scope) for startup launches; this covers the session.
foreach ($wm in 'komorebi','whkd','yasb') {
  $var = $wm.ToUpper() + '_CONFIG_HOME'
  if (-not (Get-Item "env:$var" -ErrorAction SilentlyContinue)) {
    Set-Item "env:$var" (Join-Path $env:XDG_CONFIG_HOME $wm)
  }
}
if (-not $env:EDITOR) { $env:EDITOR = 'micro' }
# micro: force 24-bit truecolor so the catppuccin-mocha colorscheme renders with
# its true palette instead of the 256-color approximation.
if (-not $env:MICRO_TRUECOLOR) { $env:MICRO_TRUECOLOR = '1' }

# ── mise — static env injection, NOT `mise activate` (runs before tool blocks) ──────
# `mise activate`'s chpwd hook corrupts the env on every cd on Windows (zoxide `z` then
# fails with "cannot find binary path"), so inject the tool PATH/env once instead.
# `--cd $HOME`: mise only emits the install dirs when CWD is inside the home tree, so a
# shell that starts at a drive root (a terminal whose startingDirectory is outside $HOME)
# would otherwise get an empty injection and fall back to the flaky shims. --cd doesn't move
# the shell. Trade-off: no per-directory version switching — fine for an all-global set.
if (Get-Command mise -ErrorAction SilentlyContinue) {
  $miseEnv = mise --cd $HOME env -s pwsh 2>$null | Out-String
  if ($miseEnv) { Invoke-Expression $miseEnv }
}

# ── chezmoi (dotfiles manager) aliases ────────────────────────────────────────────
if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
  function cz   { chezmoi @args }
  function cza  { chezmoi apply @args }   # apply changes to $HOME
  function cze  { chezmoi edit @args }    # edit a managed file in $EDITOR
  function czu  { chezmoi update @args }  # git pull, then apply
  function czd  { chezmoi diff @args }    # show what apply would change
  function czs  { chezmoi status @args }  # short per-file status
  function czra { chezmoi re-add @args }  # capture $HOME edits back into the source repo
  function czcd { chezmoi cd @args }      # cd into the source repo
}

# ── Antigravity IDE (VS Code fork; its CLI ships as `antigravity-ide`, no short name) ──
if (Get-Command antigravity-ide -ErrorAction SilentlyContinue) {
  Set-Alias agide antigravity-ide
}

# ── yasb ──────────────────────────────────────────────────────────────────────────
# `yasbr` is a full restart, NOT `yasbc reload`. yasb 2.0.7 registers its audio
# endpoint callback exactly once and swallows every failure, so the volume readout
# freezes for good after the default device drops out (USB audio, dock/monitor sleep).
# Only stop+start re-registers it. See dot_config/yasb/AGENTS.md.
if (Get-Command yasbc -ErrorAction SilentlyContinue) {
  function yasbr { yasbc stop; Start-Sleep -Seconds 2; yasbc start }
}

# ── eza (ls replacement) ──────────────────────────────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
  # PowerShell resolves ALIASES before FUNCTIONS, so the shipped `ls`→Get-ChildItem
  # alias shadows the function below and `ls` keeps the built-in output. Drop the alias
  # so `ls` runs eza. (la/ll/lt/lm/... have no built-in alias; `tree` is an .exe, which a
  # function already outranks.) -Force clears the read-only flag set on some PS builds.
  Remove-Item Alias:ls -Force -ErrorAction Ignore
  function ls  { eza --group-directories-first --icons=auto @args }
  function la  { eza --group-directories-first --icons=auto -a @args }
  function ll  { eza --group-directories-first --icons=auto -l --git --time-style=relative @args }
  function lla { eza --group-directories-first --icons=auto -la --git --time-style=relative @args }
  function tree { eza --group-directories-first --icons=auto --tree @args }  # replaces the tree binary
  function lt  { eza --group-directories-first --icons=auto --tree @args }
  function lt2 { eza --group-directories-first --icons=auto --tree --level=2 @args }
  function lt3 { eza --group-directories-first --icons=auto --tree --level=3 @args }
  function lta { eza --group-directories-first --icons=auto --tree -a @args }
  function lm  { eza --group-directories-first --icons=auto -l --sort=modified --reverse --time-style=relative @args }
  function lz  { eza --group-directories-first --icons=auto -l --sort=size --reverse @args }
}

# ── bat / fd / ripgrep — point tools at the ~/.config tree ─────────────────────────
if (Get-Command bat -ErrorAction SilentlyContinue) {
  $env:BAT_CONFIG_PATH = Join-Path $env:XDG_CONFIG_HOME 'bat\config'
}
if (Get-Command fd -ErrorAction SilentlyContinue) { $env:FD_OPTIONS = '--follow --hidden' }
if (Get-Command rg -ErrorAction SilentlyContinue) {
  $env:RIPGREP_CONFIG_PATH = Join-Path $env:XDG_CONFIG_HOME 'ripgrep\ripgreprc'
}

# ── PSReadLine — history-based inline suggestions + bash-style Tab ───────────────
# No Import-Module: the console host loads PSReadLine before $PROFILE runs, so testing
# whether it is LOADED also skips the block in a non-interactive host (pwsh -Command with
# piped stdin, e.g. Claude Code's tool shell) where there is no line editor to configure.
# PredictionSource needs PSReadLine 2.1+; this profile is also dot-sourced from WinPS 5.1's
# $PROFILE, which ships 2.0.0 and would throw on every launch. PredictionViewStyle is left
# at its default (InlineView); set ListView here to get the multi-row picker instead.
if ($psrl = Get-Module PSReadLine) {
  # try/catch, not -ErrorAction: PSReadLine THROWS (terminating) when console output is
  # redirected or lacks VT processing, so -EA SilentlyContinue does not suppress it. A
  # cosmetic suggestion feature failing to turn on must not paint the profile red.
  if ($psrl.Version -ge [version]'2.1') {
    try { Set-PSReadLineOption -PredictionSource History } catch { }
  }
  # Complete = bash-style (common prefix, then list); the PSFzf block below swaps in fzf.
  Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# ── fzf — env defaults; key-bindings need the PSFzf module (loaded if present) ──────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
  $env:FZF_DEFAULT_COMMAND = 'fd --type f'
  # Layout + preview UX mirrored from the zsh config (these opts are fzf-level, not
  # shell-specific) + catppuccin-mocha palette synced with the micro editor theme.
  #   ctrl-/  cycle preview (large → hidden → default) · ctrl-f/-b page preview
  #   shift-down/-up scroll preview a line · alt-down/-up jump to bottom/top
  $env:FZF_DEFAULT_OPTS    = @(
    '--height=80% --min-height=20 --multi --layout=reverse --cycle'
    '--border=rounded --margin=0,1 --info=inline-right --scrollbar="█│" --separator="─"'
    '--prompt="❯ " --pointer="▶" --marker="✚"'
    '--bind="ctrl-f:preview-page-down,ctrl-b:preview-page-up"'
    '--bind="shift-down:preview-down,shift-up:preview-up"'
    '--bind="alt-down:preview-bottom,alt-up:preview-top"'
    '--color bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#ff5189'
    '--color fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#ff5189'
    '--color marker:#ff5189,fg+:#cdd6f4,prompt:#cba6f7,hl+:#ff5189'
    '--color selected-bg:#45475a,border:#313244,label:#cdd6f4'
  ) -join ' '
  $env:FZF_CTRL_R_OPTS     = '--no-preview'
  $env:FZF_CTRL_T_COMMAND  = "rg --files --hidden --follow --glob '!.git/*'"
  # The preview layout lives HERE, not in FZF_DEFAULT_OPTS: fzf merges a later
  # --preview-window into the earlier one and KEEPS its `<90(...)` alternative, so PSFzf's
  # Tab picker ('hidden') still opened its broken preview in a narrow window
  # ('fork/exec cmd.exe: invalid argument').
  $env:FZF_CTRL_T_OPTS     = @(
    '--preview "bat --style=numbers --color=always --line-range=:500 {}"'
    '--preview-window="right,60%,border-left,wrap,<90(down,60%,border-top)"'
    '--bind="ctrl-/:change-preview-window(down,75%,border-top|hidden|)"'
  ) -join ' '
  # PSFzf binds fzf to PSReadLine chords (installed by the bootstrap, via pwsh — see
  # AGENTS.md). Tab completion picker · Ctrl+t file picker · Ctrl+r history · Alt+c cd into a
  # subdirectory. Ctrl+t/Ctrl+r override PSReadLine's own SwapCharacters/ReverseSearchHistory.
  # LAZY: importing PSFzf costs ~150ms, a third of the whole profile, so the chords are bound
  # here and the module loads on the FIRST keypress instead (PowerShell would auto-load it from
  # the exported handler anyway; Use-PSFzf adds the one option and a fallback).
  # Only when an interactive line editor is loaded (same gate as the PSReadLine block).
  if (Get-Module PSReadLine) {
    function global:Use-PSFzf {
      if (Get-Module PSFzf) { return $true }
      try { Import-Module PSFzf -Global -ErrorAction Stop } catch { return $false }
      # ponytail: tab preview hidden ('hidden|hidden' also pins ctrl-/) - PSFzf 2.7.12 passes {}
      # to it, and each line carries a NUL delimiter, so exec fails ('cmd.exe: invalid
      # argument'); its preview command is also empty on pwsh 7. Drop once upstream is fixed.
      Set-PsFzfOption -TabCompletionPreviewWindow 'hidden|hidden'
      $true
    }
    # Tab and Ctrl+r fall back to PSReadLine's own function if PSFzf is missing or fails.
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
      if (Use-PSFzf) { Invoke-FzfTabCompletion } else { [Microsoft.PowerShell.PSConsoleReadLine]::Complete($null, $null) }
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
      if (Use-PSFzf) { Invoke-FzfPsReadlineHandlerHistory } else { [Microsoft.PowerShell.PSConsoleReadLine]::ReverseSearchHistory($null, $null) }
    }
    Set-PSReadLineKeyHandler -Chord Ctrl+t -ScriptBlock { if (Use-PSFzf) { Invoke-FzfPsReadlineHandlerProvider } }
    Set-PSReadLineKeyHandler -Chord Alt+c  -ScriptBlock { if (Use-PSFzf) { Invoke-FzfPsReadlineHandlerSetLocation } }
  }
}

# ── cached init scripts (gh / starship / zoxide) ──────────────────────────────────────
# Each tool's generated init script is written ONCE to ~/.cache/pwsh and dot-sourced after
# that: spawning the three tools on every launch cost ~180ms of a ~450ms profile. The cache
# file is named after the exe's FULL PATH, and mise install paths embed the version
# (...\installs\starship\1.26.0\starship.exe), so an upgrade is a new path = a fresh cache,
# with no invalidation logic. -DependsOn adds a config file's mtime to the key, for a script
# that bakes in something read from that config. -Transform post-processes the text once, at
# generation. Delete ~/.cache/pwsh to force a rebuild. Returns the file to dot-source at THIS
# scope (dot-sourcing inside the function would scope its definitions).
$InitCacheDir = Join-Path $HOME '.cache\pwsh'
function Get-InitScript([string]$Tool, [string[]]$InitArgs, [string]$DependsOn, [scriptblock]$Transform) {
  $exe = (Get-Command $Tool -CommandType Application -ErrorAction Ignore | Select-Object -First 1).Source
  if (-not $exe) { return }
  $key = $exe
  if ($DependsOn -and (Test-Path $DependsOn)) { $key += '_' + (Get-Item $DependsOn).LastWriteTimeUtc.Ticks }
  $file = Join-Path $InitCacheDir (($key -replace '[^A-Za-z0-9._-]', '_') + '.ps1')
  if (-not (Test-Path $file) -or (Get-Item $file).Length -eq 0) {
    $text = & $exe @InitArgs 2>$null | Out-String
    if (-not $text) { return }
    if ($Transform) { $text = & $Transform $text $exe }
    $null = New-Item -ItemType Directory -Force $InitCacheDir
    # temp + rename so two windows opening at once never dot-source a half-written file;
    # UTF-8 WITH BOM so WinPS 5.1 (which also loads this profile) reads it correctly.
    $tmp = "$file.$PID"
    [IO.File]::WriteAllText($tmp, $text, [Text.UTF8Encoding]::new($true))
    Move-Item $tmp $file -Force
  }
  $file
}
# ponytail: superseded caches (old tool versions, old starship.toml edits) are never pruned
# (~10KB each); rm the dir if it grows.

# ── gh (GitHub CLI) completion ──────────────────────────────────────────────────────
if ($f = Get-InitScript gh 'completion', '-s', 'powershell') { . $f }

# ── starship (prompt; Windows uses it where Unix uses powerlevel10k) ──────────────────
# `init powershell` only prints a one-liner that re-spawns starship with --print-full-init;
# cache the full script directly. That script ALSO spawns `starship prompt --continuation` at
# load time (~60ms) just to set PSReadLine's ContinuationPrompt, whose value depends only on
# starship.toml - so bake the string in once, keyed on the config's mtime. If a future
# starship reshapes that call the -replace simply matches nothing and the spawn stays.
$StarshipConfig = if ($env:STARSHIP_CONFIG) { $env:STARSHIP_CONFIG } else { Join-Path $env:XDG_CONFIG_HOME 'starship.toml' }
$f = Get-InitScript starship 'init', 'powershell', '--print-full-init' -DependsOn $StarshipConfig -Transform {
  param($text, $exe)
  $cont = (& $exe prompt --continuation) -join ''
  $text -replace '(?s)Set-PSReadLineOption -ContinuationPrompt \(\s*Invoke-Native .*?"--continuation"\s*\)\s*\)',
                 ("Set-PSReadLineOption -ContinuationPrompt '" + $cont.Replace("'", "''") + "'")
}
if ($f) { . $f }

# ── zoxide (smart cd; defines z/zi, also maps cd/cdi) — MUST init AFTER starship ─────
# zoxide records visited dirs via a hook that WRAPS the current `prompt` function. starship
# REPLACES `prompt`, so if zoxide inits first, starship clobbers the hook and no directory
# is ever recorded (`z foo` → "not found"). Initializing zoxide last makes it wrap starship's
# prompt, so the prompt renders AND every cd gets tracked.
# zoxide uses the shell-name `powershell` (NOT `pwsh`).
if ($f = Get-InitScript zoxide 'init', 'powershell') {
  $env:_ZO_DOCTOR = '0'
  . $f
  # Mirror the zsh `alias cd="z"` / `alias cdi="zi"` so `cd <keyword>` jumps via zoxide
  # (the zsh conf.d does the same). __zoxide_z still cd's literally when the arg is a real
  # path (cd .., cd C:\, cd .\sub), and only fuzzy-jumps when it isn't — so nothing breaks.
  # -Force overrides the built-in read-only `cd`→Set-Location alias; AllScope follows the
  # built-in into nested scopes/functions.
  # Skip inside Claude Code's tool shell (CLAUDECODE=1): there a `cd <badpath>` routes to
  # zoxide and leaks "zoxide: no match found" into piped output, corrupting rtk/grep/JSON
  # pipelines. Keep the real `cd` there; humans outside Claude still get zoxide jumps.
  if (-not $env:CLAUDECODE) {
    Set-Alias -Name cd  -Value __zoxide_z  -Option AllScope -Scope Global -Force
    Set-Alias -Name cdi -Value __zoxide_zi -Option AllScope -Scope Global -Force
    # __zoxide_z takes bare $args, so PowerShell only completes paths under CWD: `cd ch<Tab>`
    # found nothing when no local dir matched. Complete local dirs + zoxide's matches instead
    # (a -Native completer is honored for functions and replaces the path fallback).
    Register-ArgumentCompleter -Native -CommandName cd, z, __zoxide_z -ScriptBlock {
      param($word)
      $local = [System.Management.Automation.CompletionCompleters]::CompleteFilename($word) |
        Where-Object ResultType -eq ProviderContainer
      $local
      if ($word -and $word -notmatch '[\\/:]') {
        $seen = @($local.ListItemText)
        zoxide query --list --exclude $PWD.ProviderPath -- $word 2>$null |
          Where-Object { (Split-Path $_ -Leaf) -notin $seen } |
          ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ProviderContainer', $_) }
      }
    }
  }
}

# ── machine-local overrides — sourced last, never synced ────────────────────────────
$LocalProfile = Join-Path $env:XDG_CONFIG_HOME 'powershell\profile.local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }
