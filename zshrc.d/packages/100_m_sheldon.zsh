#!/usr/bin/env zsh

# =============================================================================
# Sheldon - Fast and configurable shell plugin manager
# =============================================================================

# -----------------------------------------------------------------------------
# Package Configuration
# -----------------------------------------------------------------------------
PACKAGE_NAME="sheldon"
PACKAGE_DESC="A fast and configurable shell plugin manager"
PACKAGE_DEPS=""
PACKAGE_TYPE="custom"

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------
pre_install() {
  log_debug "Preparing sheldon installation..."
  return 0
}

post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME installation verification failed"
    return 1
  fi

  log_debug "Setting up sheldon configuration..."
  
  # Ensure sheldon config directory exists
  local sheldon_config_dir="${HOME}/.config/sheldon"
  local sheldon_config_file="${sheldon_config_dir}/plugins.toml"

  mkdir -p "$sheldon_config_dir" 2>/dev/null

  # Copy config file if it doesn't exist
  if [[ ! -f "$sheldon_config_file" && -f "${DOTFILES_ROOT}/config/sheldon/plugins.toml" ]]; then
    cp "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "$sheldon_config_file"
    log_debug "Copied sheldon configuration file"
  fi

  # Update sheldon plugins and lock file
  if sheldon lock --update &>/dev/null; then
    log_success "Sheldon plugins updated successfully"
  else
    log_warning "Failed to update sheldon plugins, but continuing..."
  fi

  # Initialize sheldon
  eval "$(sheldon source)" &>/dev/null
  return 0
}

# -----------------------------------------------------------------------------
# Custom Installation
# -----------------------------------------------------------------------------
install_custom() {
  log_info "Installing $PACKAGE_NAME using custom method..."
  
  local pm=$(get_package_manager)
  local success=false

  case "$pm" in
    brew)
      brew install sheldon &>/dev/null && success=true
      ;;
    apt)
      # Ubuntu/Debian - use official installer
      if sudo apt update &>/dev/null && sudo apt install -y curl &>/dev/null && \
         curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" &>/dev/null; then
        success=true
      fi
      ;;
    dnf|yum|pacman|zypper|pkg)
      # Try standard package manager first
      case "$pm" in
        dnf) sudo dnf install -y sheldon &>/dev/null && success=true ;;
        yum) sudo yum install -y sheldon &>/dev/null && success=true ;;
        pacman) sudo pacman -S --noconfirm sheldon &>/dev/null && success=true ;;
        zypper) sudo zypper install -y sheldon &>/dev/null && success=true ;;
        pkg) sudo pkg install sheldon &>/dev/null && success=true ;;
      esac
      ;;
    custom|*)
      # Fallback: official installer
      curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" &>/dev/null && success=true
      ;;
  esac

  if [[ "$success" == "true" ]]; then
    log_success "Sheldon installed successfully"
    return 0
  else
    log_error "Failed to install sheldon"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Package Initialization
# -----------------------------------------------------------------------------
init() {
  if is_package_installed "$PACKAGE_NAME"; then
    log_debug "Initializing sheldon plugin manager"
    
    # Ensure sheldon config directory exists
    local sheldon_config_dir="${HOME}/.config/sheldon"
    local sheldon_config_file="${sheldon_config_dir}/plugins.toml"

    mkdir -p "$sheldon_config_dir" 2>/dev/null

    # Copy config file if it doesn't exist
    if [[ ! -f "$sheldon_config_file" && -f "${DOTFILES_ROOT}/config/sheldon/plugins.toml" ]]; then
      cp "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "$sheldon_config_file"
    fi

    # Ensure sheldon is properly sourced
    if command -v sheldon &>/dev/null && [[ -f "$sheldon_config_file" ]]; then
      eval "$(sheldon source)" &>/dev/null
      return 0
    fi
  else
    log_debug "Sheldon not available, skipping initialization"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Automatic Installation Flow
# -----------------------------------------------------------------------------
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install || return 1
  install_custom && post_install
fi
