#!/usr/bin/env zsh

# =============================================================================
# Tmux - Terminal multiplexer
# =============================================================================

# Package information
PACKAGE_NAME="tmux"
PACKAGE_DESC="Terminal multiplexer for managing multiple terminal sessions"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing tmux installation..."
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
  # Only run if tmux is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing tmux environment"
    fi
    
    # Set tmux-specific environment variables
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    
    # Create tmux plugin directory if it doesn't exist
    if [[ ! -d "$TMUX_PLUGIN_MANAGER_PATH" ]]; then
      mkdir -p "$TMUX_PLUGIN_MANAGER_PATH"
    fi
    
    # Set tmux aliases
    alias t="tmux"
    alias ta="tmux attach"
    alias tl="tmux list-sessions"
    alias tn="tmux new-session"
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "tmux not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install tmux using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
