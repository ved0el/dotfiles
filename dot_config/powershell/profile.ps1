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
Remove-Item env:MISE_GLOBAL_CONFIG_FILE -ErrorAction SilentlyContinue
Remove-Item env:MISE_CONFIG_DIR -ErrorAction SilentlyContinue
# WM config homes (wm profile): komorebi/whkd/yasb read ~/.config/<tool>. komorebi
# defaults to ~/komorebi.json and whkd to ~/.config/whkdrc, so these are needed. The
# bootstrap persists them (User scope) for startup launches; this covers the session.
foreach ($wm in 'komorebi','whkd','yasb') {
  $var = $wm.ToUpper() + '_CONFIG_HOME'
  if (-not (Get-Item "env:$var" -ErrorAction SilentlyContinue)) {
    Set-Item "env:$var" (Join-Path $env:XDG_CONFIG_HOME $wm)
  }
}
if (-not $env:EDITOR) { $env:EDITOR = 'vim' }

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
  function czcd { chezmoi cd @args }      # cd into the source repo
}

# ── eza (ls replacement) ──────────────────────────────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
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

# ── fzf — env defaults; key-bindings need the PSFzf module (loaded if present) ──────
if (Get-Command fzf -ErrorAction SilentlyContinue) {
  $env:FZF_DEFAULT_COMMAND = 'fd --type f'
  $env:FZF_DEFAULT_OPTS    = '--height 75% --multi --reverse --margin=0,1 --prompt="❯ "'
  $env:FZF_CTRL_T_COMMAND  = "rg --files --hidden --follow --glob '!.git/*'"
  if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  }
}

# ── zoxide (smart cd; defines z/zi and shadows cd) ──────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  $env:_ZO_DOCTOR = '0'
  # zoxide uses the shell-name `powershell` (NOT `pwsh`).
  $init = zoxide init powershell 2>$null | Out-String
  if ($init) { Invoke-Expression $init }
}

# ── gh (GitHub CLI) completion ──────────────────────────────────────────────────────
if (Get-Command gh -ErrorAction SilentlyContinue) {
  $init = gh completion -s powershell 2>$null | Out-String
  if ($init) { Invoke-Expression $init }
}

# ── starship (prompt; Windows uses it where Unix uses powerlevel10k) ──────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
  $init = starship init powershell 2>$null | Out-String
  if ($init) { Invoke-Expression $init }
}

# ── machine-local overrides — sourced last, never synced ────────────────────────────
$LocalProfile = Join-Path $env:XDG_CONFIG_HOME 'powershell\profile.local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }
