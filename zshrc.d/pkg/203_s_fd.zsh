#!/usr/bin/env zsh

# =============================================================================
# FD - A simple, fast and user-friendly alternative to find
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="fd"
PACKAGE_DESC="A simple, fast and user-friendly alternative to find"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing fd installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up fd configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if fd is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up fd aliases"
  
  # Create aliases for fd (lightweight)
  alias find="fd"
  
  # Set up fd configuration
  export FD_OPTIONS="--follow --exclude .git --exclude node_modules"
  
  return 0
}

# Skip template system for faster loading
# FD is ready to use