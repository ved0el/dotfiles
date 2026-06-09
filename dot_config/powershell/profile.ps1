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
  function czcd { chezmoi cd @args }      # cd into the source repo
}

# ── eza (ls replacement) ──────────────────────────────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
  # PowerShell resolves ALIASES before FUNCTIONS, so the shipped `ls`→Get-ChildItem
  # alias shadows the function below and `ls` keeps the built-in output. Drop the alias
  # so `ls` runs eza. (la/ll/lt/lm/... have no built-in alias; `tree` is an .exe, which a
  # function already outranks.) -Force clears the read-only flag set on some PS builds.
  Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
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
  # Layout + preview UX mirrored from the zsh config (these opts are fzf-level, not
  # shell-specific) + catppuccin-mocha palette synced with the micro editor theme.
  #   ctrl-/  cycle preview (large → hidden → default) · ctrl-f/-b page preview
  #   shift-down/-up scroll preview a line · alt-down/-up jump to bottom/top
  $env:FZF_DEFAULT_OPTS    = @(
    '--height=80% --min-height=20 --multi --layout=reverse --cycle'
    '--border=rounded --margin=0,1 --info=inline-right --scrollbar="█│" --separator="─"'
    '--prompt="❯ " --pointer="▶" --marker="✚"'
    '--preview-window="right,60%,border-left,wrap,<90(down,60%,border-top)"'
    '--bind="ctrl-/:change-preview-window(down,75%,border-top|hidden|)"'
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
  $env:FZF_CTRL_T_OPTS     = '--preview "bat --style=numbers --color=always --line-range=:500 {}"'
  if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  }
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

# ── zoxide (smart cd; defines z/zi, also maps cd/cdi) — MUST init AFTER starship ─────
# zoxide records visited dirs via a hook that WRAPS the current `prompt` function. starship
# REPLACES `prompt`, so if zoxide inits first, starship clobbers the hook and no directory
# is ever recorded (`z foo` → "not found"). Initializing zoxide last makes it wrap starship's
# prompt, so the prompt renders AND every cd gets tracked.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  $env:_ZO_DOCTOR = '0'
  # zoxide uses the shell-name `powershell` (NOT `pwsh`).
  $init = zoxide init powershell 2>$null | Out-String
  if ($init) { Invoke-Expression $init }
  # Mirror the zsh `alias cd="z"` / `alias cdi="zi"` so `cd <keyword>` jumps via zoxide
  # (the zsh conf.d does the same). __zoxide_z still cd's literally when the arg is a real
  # path (cd .., cd C:\, cd .\sub), and only fuzzy-jumps when it isn't — so nothing breaks.
  # -Force overrides the built-in read-only `cd`→Set-Location alias; AllScope follows the
  # built-in into nested scopes/functions.
  Set-Alias -Name cd  -Value __zoxide_z  -Option AllScope -Scope Global -Force
  Set-Alias -Name cdi -Value __zoxide_zi -Option AllScope -Scope Global -Force
}

# ── machine-local overrides — sourced last, never synced ────────────────────────────
$LocalProfile = Join-Path $env:XDG_CONFIG_HOME 'powershell\profile.local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }
