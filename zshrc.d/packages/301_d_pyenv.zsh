#!/usr/bin/env zsh

# =============================================================================
# Pyenv - Python version manager
# =============================================================================

# Package information
PACKAGE_NAME="pyenv"
PACKAGE_DESC="Python version manager"
PACKAGE_DEPS="git curl"  # Requires git and curl

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing pyenv installation..."
  fi
  
  # Create pyenv directory
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  mkdir -p "$PYENV_ROOT"
  
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Setting up pyenv configuration..."
  fi

  # Set up pyenv environment
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"
  
  # Install Python LTS version
  if command -v pyenv &>/dev/null; then
    pyenv install --list | grep " 3\." | tail -1 | xargs pyenv install
    pyenv global $(pyenv versions --bare | tail -1)
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_success "$PACKAGE_NAME installed and ready"
  fi
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if pyenv is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing pyenv"
    fi
    
    # Set up pyenv environment
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # Initialize pyenv
    if command -v pyenv &>/dev/null; then
      eval "$(pyenv init -)"
      eval "$(pyenv init --path)"
    fi
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "Pyenv not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install pyenv using custom logic (needs special installer)
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  
  # Pyenv is installed via script, not package manager
  if [[ ! -d "$HOME/.pyenv" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Installing $PACKAGE_NAME..."
    fi
    curl https://pyenv.run | bash
    export PYENV_ROOT="$HOME/.pyenv"
  fi

  post_install
fi
