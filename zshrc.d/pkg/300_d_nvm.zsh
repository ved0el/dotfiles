#!/usr/bin/env zsh

# =============================================================================
# NVM - Node Version Manager
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="nvm"
PACKAGE_DESC="Node Version Manager"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing NVM installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up NVM configuration..."
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # NVM is typically installed via script, check for nvm directory
  local nvm_dir="${HOME}/.nvm"
  
  if [[ ! -d "$nvm_dir" ]]; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing NVM"
  
  # Set up lazy loading for NVM (don't load immediately)
  if [[ -f "$nvm_dir/nvm.sh" ]]; then
    # Create lazy wrapper for nvm commands
    if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh" ]]; then
      source "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh"
      create_lazy_wrapper "nvm" "lazy_load_nvm"
    fi
    return 0
  fi
  
  return 1
}

# -----------------------------------------------------------------------------
# 5. Custom Package Check (override default for NVM)
# -----------------------------------------------------------------------------
is_package_installed() {
  # NVM doesn't have a command, check for directory instead
  [[ -d "${HOME}/.nvm" ]]
}

# -----------------------------------------------------------------------------
# 5. Custom Installation (NVM needs special installer)
# -----------------------------------------------------------------------------
custom_install() {
  local success=false
  
  # Install NVM using official installer
  if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash; then
    success=true
  fi
  
  return $([ "$success" == "true" ] && echo 0 || echo 1)
}

# -----------------------------------------------------------------------------
# 6. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"