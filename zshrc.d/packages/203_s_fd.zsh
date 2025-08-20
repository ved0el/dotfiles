#!/usr/bin/env zsh

# =============================================================================
# FD - Fast finder
# =============================================================================

# Package information
PACKAGE_NAME="fd"
PACKAGE_DESC="Fast finder alternative to find"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing fd installation..."
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
  # Only run if fd is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing fd"
    fi
    
    # Set up fd aliases
    alias find="fd"
    
    # Set fd configuration for better performance
    export FZF_DEFAULT_COMMAND="fd --type f"
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "FD not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install fd using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
