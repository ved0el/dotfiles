#!/usr/bin/env zsh

# =============================================================================
# Goenv - Go version management
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="goenv"
PACKAGE_DESC="Go version management"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing goenv installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up goenv configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Check if goenv directory exists
  local goenv_dir="${HOME}/.goenv"
  
  if [[ ! -d "$goenv_dir" ]]; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing goenv"
  
  # Set up lazy loading for goenv (don't load immediately)
  if [[ -f "$goenv_dir/bin/goenv" ]]; then
    # Create lazy wrapper for goenv commands
    if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh" ]]; then
      source "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh"
      create_lazy_wrapper "goenv" "lazy_load_goenv"
    fi
    return 0
  fi
  
  return 1
}

# -----------------------------------------------------------------------------
# 5. Custom Installation (goenv needs special installer)
# -----------------------------------------------------------------------------
custom_install() {
  local success=false
  
  # Install goenv using git
  if git clone https://github.com/syndbg/goenv.git ~/.goenv; then
    success=true
  fi
  
  return $([ "$success" == "true" ] && echo 0 || echo 1)
}

# -----------------------------------------------------------------------------
# 6. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"