#!/usr/bin/env zsh

# =============================================================================
# FZF - Fuzzy Finder
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="fzf"
PACKAGE_DESC="A command-line fuzzy finder"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing FZF installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up FZF configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if fzf is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing FZF configuration"
  
  # Set FZF configuration every time shell starts
  export FZF_DEFAULT_COMMAND="fd --type f"
  export FZF_DEFAULT_OPTS="
    --height 75% --multi --reverse --margin=0,1 \
    --bind ctrl-f:page-down,ctrl-b:page-up,ctrl-/:toggle-preview \
    --bind pgdn:preview-page-down,pgup:preview-page-up \
    --preview 'bat --line-range :100 {}' \
    --marker='✚' --pointer='▶' --prompt='❯ ' --no-separator --scrollbar='█' \
    --color bg+:#262626,fg+:#f0dada,hl:#f09479,hl+:#f09479 \
    --color marker:#f09479,spinner:#f09479,header:#f09479,info:#f0dada \
    --color prompt:#f0dada,pointer:#f09479,marker:#f09479,spinner:#f09479 \
    --color header:#f09479,info:#f0dada,prompt:#f0dada,pointer:#f09479"
  
  # Key bindings
  if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
  fi
  
  return 0
}

# -----------------------------------------------------------------------------
# 5. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"