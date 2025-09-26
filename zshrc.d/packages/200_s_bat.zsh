#!/usr/bin/env zsh

# =============================================================================
# Bat - A cat clone with syntax highlighting and Git integration
# =============================================================================

# -----------------------------------------------------------------------------
# Package Configuration
# -----------------------------------------------------------------------------
PACKAGE_NAME="bat"
PACKAGE_DESC="A cat clone with syntax highlighting and Git integration"
PACKAGE_DEPS=""
PACKAGE_TYPE="standard"

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------
pre_install() {
  log_debug "Preparing bat installation..."
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  return 0
}

post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME installation verification failed"
    return 1
  fi

  # Create batcat symlink for Ubuntu/Debian compatibility
  if [[ "$(get_platform)" == "linux" ]] && ! command -v batcat &>/dev/null; then
    sudo ln -sf "$(which bat)" /usr/local/bin/batcat 2>/dev/null || true
  fi

  log_success "$PACKAGE_NAME installed and ready"
  return 0
}

# -----------------------------------------------------------------------------
# Package Initialization
# -----------------------------------------------------------------------------
init() {
  if is_package_installed "$PACKAGE_NAME"; then
    log_debug "Initializing bat..."
    
    # Set bat as the default pager for man pages
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    
    # Create alias for better compatibility
    alias cat="bat"
    
    return 0
  else
    log_debug "bat not available, skipping initialization"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Automatic Installation Flow
# -----------------------------------------------------------------------------
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install || return 1
  install_package "$PACKAGE_NAME" "$PACKAGE_DESC" && post_install
fi
