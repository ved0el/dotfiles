#!/usr/bin/env zsh

# =============================================================================
# FZF - Fuzzy Finder
# =============================================================================

# Package information
PACKAGE_NAME="fzf"
PACKAGE_DESC="A command-line fuzzy finder"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing FZF installation..."
  fi
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_success "$PACKAGE_NAME installed and ready"
  fi
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if fzf is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing FZF configuration"
    fi
    
    # Set FZF configuration every time shell starts
    export FZF_DEFAULT_COMMAND="fd --type f"
    export FZF_DEFAULT_OPTS="
      --height 75% --multi --reverse --margin=0,1 \
      --bind ctrl-f:page-down,ctrl-b:page-up,ctrl-/:toggle-preview \
      --bind pgdn:preview-page-down,pgup:preview-page-up \
      --preview 'bat --line-range :100 {}' \
      --marker='✚' --pointer='▶' --prompt='❯ ' --no-separator --scrollbar='█' \
      --color bg+:#262626,fg+:#fdada,hl:#f09479,hl+:#f09479 \
      --color border:#303030,info:#cfcfb0,header:#80a0ff,spinner:#36c692 \
      --color prompt:#87afff,pointer:#ff5189,marker:#f09479"
    export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
    export FZF_CTRL_T_OPTS="--preview 'bat --line-range :100 {}'"
    export FZF_ALT_C_COMMAND="fd --type d"
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "FZF not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install fzf using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
