#!/usr/bin/env zsh

# =============================================================================
# Optimized Package Management Library - Fast startup with caching
# =============================================================================

# -----------------------------------------------------------------------------
# Fast Package Installation Functions
# -----------------------------------------------------------------------------

# Fast package check with caching
typeset -g __PKG_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/packages"
typeset -g __PKG_CACHE_FILE="${__PKG_CACHE_DIR}/package_states"
typeset -g __PKG_CACHE_AGE=3600  # 1 hour cache

# Initialize cache directory
init_package_cache() {
    if [[ ! -d "$__PKG_CACHE_DIR" ]]; then
        mkdir -p "$__PKG_CACHE_DIR" 2>/dev/null
    fi
}

# Ultra-fast package check (cached)
is_package_installed() {
    local package_name="$1"
    local cache_file="$__PKG_CACHE_FILE"
    
    # Fast cache check
    if [[ -f "$cache_file" ]] && grep -q "^${package_name}:installed$" "$cache_file" 2>/dev/null; then
        return 0
    fi
    
    # Quick command check
    if command -v "$package_name" &>/dev/null; then
        # Update cache
        echo "${package_name}:installed" >> "$cache_file" 2>/dev/null
        return 0
    fi
    
    return 1
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
    # Update cache
    sed -i '' "/^${package_name}:/d" "$__PKG_CACHE_FILE" 2>/dev/null
    echo "${package_name}:installed" >> "$__PKG_CACHE_FILE"
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
    # Update cache
    sed -i '' "/^${package_name}:/d" "$__PKG_CACHE_FILE" 2>/dev/null
    echo "${package_name}:installed" >> "$__PKG_CACHE_FILE"
    return 0
  else
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Error: Failed to install $package_name"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Optimized Package Management Functions
# -----------------------------------------------------------------------------

# Removed complex run_package_install function - using simplified init_package_template instead

# -----------------------------------------------------------------------------
# Utility Functions (optimized)
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
# Fast Package Template Functions
# -----------------------------------------------------------------------------

# Ultra-fast package template initialization
init_package_template() {
  local package_name="$1"
  
  # Fast check if already installed
  if is_package_installed "$package_name"; then
    # Run init function if available
    typeset -f "init" >/dev/null && init
    return $?
  fi
  
  # Not installed - run installation flow
  typeset -f "pre_install" >/dev/null && pre_install
  typeset -f "custom_install" >/dev/null && custom_install || install_package "$package_name"
  typeset -f "post_install" >/dev/null && post_install
  typeset -f "init" >/dev/null && init
}

# Initialize cache
init_package_cache
