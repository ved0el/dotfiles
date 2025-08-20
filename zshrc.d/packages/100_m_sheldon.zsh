#!/usr/bin/env zsh

# =============================================================================
# Sheldon - Fast and configurable shell plugin manager
# =============================================================================

# Package information
PACKAGE_NAME="sheldon"
PACKAGE_DESC="A fast and configurable shell plugin manager"
PACKAGE_DEPS=""  # No dependencies

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing sheldon installation..."
  fi
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Setting up sheldon configuration..."
  fi

  # Update sheldon plugins and lock file
  if sheldon lock --update &>/dev/null; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_success "Sheldon plugins updated successfully"
    fi
  fi

  # Initialize sheldon
  eval "$(sheldon source)" &>/dev/null
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if sheldon is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing sheldon plugin manager"
    fi
    
    # Ensure sheldon is properly sourced
    if command -v sheldon &>/dev/null; then
      eval "$(sheldon source)" &>/dev/null
      return 0
    fi
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "Sheldon not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install sheldon using custom logic (needs special installer)
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  
  local pm=$(get_package_manager)
  local success=false

  case "$pm" in
    brew)
      if brew install sheldon &>/dev/null; then
        success=true
      fi
      ;;
    apt)
      # Ubuntu/Debian - use official installer
      if sudo apt update &>/dev/null && sudo apt install -y curl &>/dev/null && \
         curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" &>/dev/null; then
        success=true
      fi
      ;;
    dnf)
      if sudo dnf install -y sheldon &>/dev/null; then
        success=true
      fi
      ;;
    yum)
      if sudo yum install -y sheldon &>/dev/null; then
        success=true
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm sheldon &>/dev/null; then
        success=true
      fi
      ;;
    zypper)
      if sudo zypper install -y sheldon &>/dev/null; then
        success=true
      fi
      ;;
    pkg)
      if sudo pkg install sheldon &>/dev/null; then
        success=true
      fi
      ;;
    custom)
      # Fallback: official installer
      if curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" &>/dev/null; then
        success=true
      fi
      ;;
  esac

  if [[ "$success" == "true" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_success "Sheldon installed successfully"
    fi
    post_install
  else
    log_error "Failed to install sheldon"
    return 1
  fi
fi
