#!/usr/bin/env zsh

# =============================================================================
# Bat - A cat clone with syntax highlighting and Git integration
# =============================================================================

# Package information
PACKAGE_NAME="bat"
PACKAGE_DESC="A cat clone with syntax highlighting and Git integration"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  # Set bat as the default pager for man pages
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  # Create batcat symlink for Ubuntu/Debian compatibility
  if [[ "$(get_platform)" == "linux" ]] && ! command -v batcat &>/dev/null; then
    sudo ln -sf "$(which bat)" /usr/local/bin/batcat 2>/dev/null || true
  fi

  log_success "$PACKAGE_NAME installed and ready"
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if bat is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    # Set bat as the default pager for man pages
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # Create alias for better compatibility
    alias cat="bat"
    
    return 0
  else
    # Package not available - skip environment setup
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install bat using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
