#!/usr/bin/env zsh

# =============================================================================
# Tealdeer - A very fast implementation of tldr in Rust
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="tldr"
PACKAGE_DESC="A very fast implementation of tldr in Rust"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing tealdeer installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up tealdeer configuration..."
  
  # Skip expensive cache update during installation
  # Cache will be updated on first use
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if tealdeer is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up tealdeer lazy loading"
  
  # Create lazy loading wrapper for tldr
  tldr() {
    # Update cache only on first use (not every startup)
    if [[ ! -f ~/.cache/tealdeer ]]; then
      command tldr --update &>/dev/null
    fi
    command tldr "$@"
  }
  
  # Create aliases for tealdeer
  alias help="tldr"
  
  return 0
}

# Skip template system for faster loading
# Tealdeer is ready to use