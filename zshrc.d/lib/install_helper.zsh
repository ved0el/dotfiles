#!/usr/bin/env zsh

# =============================================================================
# Package Management Library - Common functions for all packages
# =============================================================================

# -----------------------------------------------------------------------------
# Package Installation Functions
# -----------------------------------------------------------------------------

# Check if a package is installed
is_package_installed() {
  command -v "$1" &>/dev/null
}

# Install package using OS-specific package manager
install_package() {
  local package_name="$1"
  local success=false
  
  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
        brew install "$package_name" && success=true
      fi
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian)
            if command -v apt &>/dev/null; then
              sudo apt update && sudo apt install -y "$package_name" && success=true
            fi
            ;;
          fedora|centos|rhel|rocky|alma)
            if command -v dnf &>/dev/null; then
              sudo dnf install -y "$package_name" && success=true
            elif command -v yum &>/dev/null; then
              sudo yum install -y "$package_name" && success=true
            fi
            ;;
          arch|manjaro|endeavouros)
            if command -v pacman &>/dev/null; then
              sudo pacman -S --noconfirm "$package_name" && success=true
            fi
            ;;
          opensuse|suse)
            if command -v zypper &>/dev/null; then
              sudo zypper install -y "$package_name" && success=true
            fi
            ;;
        esac
      fi
      ;;
    FreeBSD)
      if command -v pkg &>/dev/null; then
        sudo pkg install "$package_name" && success=true
      fi
      ;;
  esac
  
  if [[ "$success" == "true" ]]; then
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Success: $package_name installed successfully"
    return 0
  else
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Error: Failed to install $package_name"
    return 1
  fi
}

# Install package using custom installer (for special cases)
install_package_custom() {
  local package_name="$1"
  local install_command="$2"
  local success=false
  
  if eval "$install_command"; then
    success=true
  fi
  
  if [[ "$success" == "true" ]]; then
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Success: $package_name installed successfully"
    return 0
  else
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Error: Failed to install $package_name"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Package Management Functions
# -----------------------------------------------------------------------------

# Run package installation flow
run_package_install() {
  local package_name="$1"
  local pre_install_func="$2"
  local post_install_func="$3"
  local init_func="$4"
  local custom_install_command="$5"
  
  # Check if package is already installed
  if is_package_installed "$package_name"; then
    # Package is installed, run initialization
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Package $package_name already installed, initializing..."
    if [[ -n "$init_func" ]] && typeset -f "$init_func" >/dev/null; then
      "$init_func"
    fi
    return $?
  fi
  
  # Package not installed, proceed with installation
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Installing $package_name..."
  
  # Run pre-installation setup
  if [[ -n "$pre_install_func" ]] && typeset -f "$pre_install_func" >/dev/null; then
    "$pre_install_func"
  fi
  
  # Install package
  local install_success=false
  if [[ -n "$custom_install_command" ]]; then
    install_package_custom "$package_name" "$custom_install_command" && install_success=true
  else
    install_package "$package_name" && install_success=true
  fi
  
  # Run post-installation setup if successful
  if [[ "$install_success" == "true" ]]; then
    if [[ -n "$post_install_func" ]] && typeset -f "$post_install_func" >/dev/null; then
      "$post_install_func"
    fi
    
    # Run initialization
    if [[ -n "$init_func" ]] && typeset -f "$init_func" >/dev/null; then
      "$init_func"
    fi
    return $?
  else
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Create directory if it doesn't exist
ensure_directory() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null
    return $?
  fi
  return 0
}

# Copy file if source exists and destination doesn't
copy_if_missing() {
  local source="$1"
  local destination="$2"
  
  if [[ -f "$source" && ! -f "$destination" ]]; then
    cp "$source" "$destination" 2>/dev/null
    return $?
  fi
  return 0
}

# Create symlink if target doesn't exist
create_symlink() {
  local target="$1"
  local link="$2"
  
  if [[ ! -e "$link" ]]; then
    ln -sf "$target" "$link" 2>/dev/null
    return $?
  fi
  return 0
}

# -----------------------------------------------------------------------------
# Package Template Functions
# -----------------------------------------------------------------------------

# Initialize package with standard template
init_package_template() {
  local package_name="$1"
  local package_desc="$2"
  local pre_install_func="pre_install"
  local post_install_func="post_install"
  local init_func="init"
  local custom_install_command=""
  
  # Check if custom install command is defined
  if typeset -f "custom_install" >/dev/null; then
    custom_install_command="custom_install"
  fi
  
  # Run the package installation flow
  run_package_install "$package_name" "$pre_install_func" "$post_install_func" "$init_func" "$custom_install_command"
}
