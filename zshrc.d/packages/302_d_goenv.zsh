#!/usr/bin/env zsh

# =============================================================================
# Goenv - Go version manager
# =============================================================================

# Package information
PACKAGE_NAME="goenv"
PACKAGE_DESC="Go version manager"
PACKAGE_DEPS="git curl"  # Requires git and curl

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing goenv installation..."
  fi
  
  # Create goenv directory
  export GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
  mkdir -p "$GOENV_ROOT"
  
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Setting up goenv configuration..."
  fi

  # Set up goenv environment
  export GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
  export PATH="$GOENV_ROOT/bin:$PATH"
  
  # Install Go LTS version
  if command -v goenv &>/dev/null; then
    goenv install $(goenv install --list | grep -E "^  [0-9]+\.[0-9]+\.[0-9]+$" | tail -1 | xargs)
    goenv global $(goenv versions --bare | tail -1)
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_success "$PACKAGE_NAME installed and ready"
  fi
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if goenv is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing goenv"
    fi
    
    # Set up goenv environment
    export GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
    export PATH="$GOENV_ROOT/bin:$PATH"
    
    # Initialize goenv
    if command -v goenv &>/dev/null; then
      eval "$(goenv init -)"
    fi
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "Goenv not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install goenv using custom logic (needs special installer)
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  
  # Goenv is installed via script, not package manager
  if [[ ! -d "$HOME/.goenv" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Installing $PACKAGE_NAME..."
    fi
    git clone https://github.com/syndbg/goenv.git ~/.goenv
    export GOENV_ROOT="$HOME/.goenv"
  fi

  post_install
fi
