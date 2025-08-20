#!/usr/bin/env zsh

# =============================================================================
# Zoxide - A smarter cd command
# =============================================================================

# Package information
PACKAGE_NAME="zoxide"
PACKAGE_DESC="A smarter cd command"
PACKAGE_DEPS="" # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing zoxide installation..."
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
  # Only run if zoxide is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing zoxide"
    fi
    
    # Initialize zoxide
    eval "$(zoxide init zsh)"
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "Zoxide not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install zoxide using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
