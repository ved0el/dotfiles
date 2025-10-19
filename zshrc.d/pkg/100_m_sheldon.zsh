#!/usr/bin/env zsh

# =============================================================================
# Sheldon - Fast and configurable shell plugin manager
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="sheldon"
PACKAGE_DESC="A fast and configurable shell plugin manager"
PACKAGE_DEPS=""  # No dependencies

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing sheldon installation..."
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up sheldon configuration..."
  
  # Ensure sheldon config directory exists
  local sheldon_config_dir="${HOME}/.config/sheldon"
  local sheldon_config_file="${sheldon_config_dir}/plugins.toml"
  
  ensure_directory "$sheldon_config_dir"
  
  # Copy config file if it doesn't exist
  copy_if_missing "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "$sheldon_config_file"
  
  # Update sheldon plugins and lock file
  if sheldon lock --update &>/dev/null; then
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Sheldon plugins updated successfully"
  else
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Warning: Failed to update sheldon plugins, but continuing..."
  fi
  
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if sheldon is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing sheldon plugin manager"
  
  # Ensure sheldon config directory exists
  local sheldon_config_dir="${HOME}/.config/sheldon"
  local sheldon_config_file="${sheldon_config_dir}/plugins.toml"
  
  ensure_directory "$sheldon_config_dir"
  
  # Copy config file if it doesn't exist
  copy_if_missing "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "$sheldon_config_file"
  
  # Set up lazy loading for sheldon (don't load immediately)
  if [[ -f "$sheldon_config_file" ]]; then
    # Create lazy wrapper for sheldon commands
    if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh" ]]; then
      source "$DOTFILES_ROOT/zshrc.d/lib/lazy_loader.zsh"
      create_lazy_wrapper "sheldon" "lazy_load_sheldon"
    fi
    return 0
  fi
  
  return 1
}

# -----------------------------------------------------------------------------
# 5. Custom Installation (for special cases)
# -----------------------------------------------------------------------------
custom_install() {
  local success=false
  
  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
        brew install "$PACKAGE_NAME" && success=true
      fi
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian)
            if command -v apt &>/dev/null; then
              sudo apt update && sudo apt install -y "$PACKAGE_NAME" && success=true
            elif command -v curl &>/dev/null; then
              # Fallback to official installer
              curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
                sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" && success=true
            fi
            ;;
          fedora|centos|rhel|rocky|alma)
            if command -v dnf &>/dev/null; then
              sudo dnf install -y "$PACKAGE_NAME" && success=true
            elif command -v yum &>/dev/null; then
              sudo yum install -y "$PACKAGE_NAME" && success=true
            fi
            ;;
          arch|manjaro|endeavouros)
            if command -v pacman &>/dev/null; then
              sudo pacman -S --noconfirm "$PACKAGE_NAME" && success=true
            fi
            ;;
          opensuse|suse)
            if command -v zypper &>/dev/null; then
              sudo zypper install -y "$PACKAGE_NAME" && success=true
            fi
            ;;
        esac
      fi
      ;;
    FreeBSD)
      if command -v pkg &>/dev/null; then
        sudo pkg install "$PACKAGE_NAME" && success=true
      fi
      ;;
  esac
  
  return $([ "$success" == "true" ] && echo 0 || echo 1)
}

# -----------------------------------------------------------------------------
# 6. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"
