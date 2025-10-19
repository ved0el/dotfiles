#!/usr/bin/env zsh

# =============================================================================
# Ripgrep - A line-oriented search tool that recursively searches directories
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="rg"
PACKAGE_DESC="A line-oriented search tool that recursively searches directories"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing ripgrep installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up ripgrep configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if ripgrep is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing ripgrep"
  
  # Create aliases for ripgrep
  alias grep="rg"
  
  # Set up ripgrep configuration
  export RIPGREP_CONFIG_PATH="${HOME}/.config/ripgrep/ripgreprc"
  
  return 0
}

# -----------------------------------------------------------------------------
# 5. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"