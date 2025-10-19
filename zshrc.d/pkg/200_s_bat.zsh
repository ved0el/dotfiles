#!/usr/bin/env zsh

# =============================================================================
# Bat - A cat clone with syntax highlighting and Git integration
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="bat"
PACKAGE_DESC="A cat clone with syntax highlighting and Git integration"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing bat installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up bat configuration..."
  
  # Create batcat symlink for Ubuntu/Debian compatibility
  if [[ "$(uname -s)" == "Linux" ]] && ! command -v batcat &>/dev/null; then
    create_symlink "$(which bat)" "/usr/local/bin/batcat"
  fi
  
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if bat is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing bat"
  
  # Set bat as the default pager for man pages
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  
  # Create alias for better compatibility
  alias cat="bat"
  
  return 0
}

# -----------------------------------------------------------------------------
# 5. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"