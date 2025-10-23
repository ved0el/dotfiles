#!/usr/bin/env zsh

# =============================================================================
# FZF - Fuzzy Finder
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="fzf"
PACKAGE_DESC="A command-line fuzzy finder"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing FZF installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up FZF configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if fzf is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up FZF configuration"
  
  # Set FZF configuration (lightweight)
  export FZF_DEFAULT_COMMAND="fd --type f"
  export FZF_DEFAULT_OPTS="--height 75% --multi --reverse"
  
  # Disable fzf completion bindings to avoid conflicts with zsh completion
  export FZF_COMPLETION_TRIGGER=''
  export FZF_COMPLETION_OPTS=''
  
  # Skip loading ~/.fzf.zsh to avoid expensive operations
  return 0
}

# Skip template system for faster loading
# FZF is ready to use