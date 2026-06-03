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
# Machine-local mise config: `mise use -g` writes here, not into the chezmoi-managed
# conf.d/*.toml (this file is chezmoi-ignored, so per-machine pins stay untracked).
if (-not $env:MISE_GLOBAL_CONFIG_FILE) {
  $env:MISE_GLOBAL_CONFIG_FILE = Join-Path $env:XDG_CONFIG_HOME 'mise\config.toml'
}
# KOMOREBI_CONFIG_HOME so komorebi (wm profile) reads ~/.config/komorebi.
if (-not $env:KOMOREBI_CONFIG_HOME) {
  $env:KOMOREBI_CONFIG_HOME = Join-Path $env:XDG_CONFIG_HOME 'komorebi'
}
if (-not $env:EDITOR) { $env:EDITOR = 'vim' }

# ── mise (runtime / CLI-tool version manager) — before tool blocks so shims exist ──
if (Get-Command mise -ErrorAction SilentlyContinue) {
  mise activate pwsh | Out-String | Invoke-Expression
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
  zoxide init pwsh | Out-String | Invoke-Expression
}

# ── gh (GitHub CLI) completion ──────────────────────────────────────────────────────
if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh completion -s powershell | Out-String | Invoke-Expression
}

# ── starship (prompt; Windows uses it where Unix uses powerlevel10k) ──────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
  starship init powershell | Out-String | Invoke-Expression
}

# ── machine-local overrides — sourced last, never synced ────────────────────────────
$LocalProfile = Join-Path $env:XDG_CONFIG_HOME 'powershell\profile.local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }
