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
  
  # Add goenv to PATH
  export PATH="$goenv_dir/bin:$PATH"
  
  # Initialize goenv
  if command -v goenv &>/dev/null; then
    eval "$(goenv init -)"
  fi
  
  return 0
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