#!/usr/bin/env zsh

# =============================================================================
# Zoxide - A smarter cd command
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="zoxide"
PACKAGE_DESC="A smarter cd command"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing zoxide installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up zoxide configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if zoxide is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing zoxide"
  
  # Only initialize zoxide in verbose mode to avoid warnings
  if [[ "$DOTFILES_VERBOSE" == "true" ]]; then
    eval "$(zoxide init zsh)"
    # Create aliases for zoxide
    alias cd="z"
    alias cdi="zi"
  else
    # In non-verbose mode, just create aliases without initialization
    # This prevents the configuration warning
    alias cd="z"
    alias cdi="zi"
  fi
  
  return 0
}

# -----------------------------------------------------------------------------
# 5. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"