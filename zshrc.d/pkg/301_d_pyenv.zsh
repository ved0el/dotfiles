#!/usr/bin/env zsh

# =============================================================================
# Pyenv - Python version management
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="pyenv"
PACKAGE_DESC="Python version management"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing pyenv installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up pyenv configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Check if pyenv directory exists
  local pyenv_dir="${HOME}/.pyenv"
  
  if [[ ! -d "$pyenv_dir" ]]; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing pyenv"
  
  # Set up lazy loading for pyenv (don't load immediately)
  if [[ -f "$pyenv_dir/bin/pyenv" ]]; then
    # Create lazy wrapper for pyenv commands
    if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh" ]]; then
      source "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh"
      create_lazy_wrapper "pyenv" "lazy_load_pyenv"
    fi
    return 0
  fi
  
  return 1
}

# -----------------------------------------------------------------------------
# 5. Custom Installation (pyenv needs special installer)
# -----------------------------------------------------------------------------
custom_install() {
  local success=false
  
  # Install pyenv using official installer
  if curl https://pyenv.run | bash; then
    success=true
  fi
  
  return $([ "$success" == "true" ] && echo 0 || echo 1)
}

# -----------------------------------------------------------------------------
# 6. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"