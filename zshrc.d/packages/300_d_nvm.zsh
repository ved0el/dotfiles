#!/usr/bin/env zsh

# =============================================================================
# NVM - Node Version Manager
# =============================================================================

# Package information
PACKAGE_NAME="nvm"
PACKAGE_DESC="Node Version Manager for managing Node.js versions"
PACKAGE_DEPS="curl git"  # Requires curl and git

# Set NVM_DIR early to avoid parameter not set errors
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing NVM installation..."
  fi
  
  export NVM_DIR="$HOME/.nvm"

  # Create nvm directory if it doesn't exist
  if [[ ! -d "$NVM_DIR" ]]; then
    mkdir -p "$NVM_DIR"
  fi
  return 0
}

# Post-installation setup (optional)
post_install() {
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    log_error "$PACKAGE_NAME installation incomplete"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Setting up NVM configuration..."
  fi

  # Load nvm
  source "$NVM_DIR/nvm.sh"

  # Install Node.js LTS version
  nvm install --lts
  nvm use --lts

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_success "$PACKAGE_NAME installed and ready"
  fi
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if nvm is available (either installed or already present)
  if [[ -n "$NVM_DIR" && -d "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing NVM lazy loading"
    fi
    
    # NVM initialization is now lazy-loaded
    # Create placeholder functions for lazy loading
    lazy_load_nvm() {
      unset -f node npm npx nvm

      export NVM_DIR="$HOME/.nvm"

      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
      fi
    }

    # Create lazy loading stubs
    node() {
      lazy_load_nvm
      node "$@"
    }

    npm() {
      lazy_load_nvm
      npm "$@"
    }

    npx() {
      lazy_load_nvm
      npx "$@"
    }

    nvm() {
      lazy_load_nvm
      nvm "$@"
    }
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "NVM not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install nvm using custom logic (needs special installer)
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install

  # NVM is installed via script, not package manager
  if [[ ! -d "$HOME/.nvm" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Installing $PACKAGE_NAME..."
    fi
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
  fi

  post_install
fi
