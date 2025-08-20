#!/usr/bin/env zsh

# =============================================================================
# Eza - A modern replacement for ls
# =============================================================================

# Package information
PACKAGE_NAME="eza"
PACKAGE_DESC="A modern replacement for ls"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing eza installation..."
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
  # Only run if eza is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing eza configuration"
    fi
    
    # Create alias for eza
    alias ls="eza"
    
    # Set zoxide fuzzy search options (only affects zoxide, not tab completion)
    export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 --group-directories-first --header --no-user --no-time --no-filesize --no-permissions {2..}' \
    --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "Eza not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install eza using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
