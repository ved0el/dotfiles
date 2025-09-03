#!/usr/bin/env zsh

# =============================================================================
# Simple Package Management System
# =============================================================================

# Logging functions
log_info()    { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;34m[INFO]\033[0m $1" }
log_warning() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;33m[WARNING]\033[0m $1" }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1" }
log_success() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;32m[SUCCESS]\033[0m $1" }

# Detect package manager
get_package_manager() {
  if command -v brew &>/dev/null; then echo "brew"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v pacman &>/dev/null; then echo "pacman"
  else echo "custom"
  fi
}

# Check if package is installed
is_package_installed() { command -v "$1" &>/dev/null; }

# Install package using detected package manager
install_package() {
  local name="$1"
  local pm="$(get_package_manager)"

  if [[ "$pm" == "custom" ]]; then
    log_warning "No supported package manager found for $name"
    return 1
  fi

  case "$pm" in
    brew) brew install "$name" ;;
    apt) sudo apt update && sudo apt install -y "$name" ;;
    dnf) sudo dnf install -y "$name" ;;
    pacman) sudo pacman -S --noconfirm "$name" ;;
  esac
}

# Get current profile (with fallback)
get_profile() { echo "${DOTFILES_PROFILE:-minimal}"; }

# Check if package should be installed for current profile
should_install_package() {
  local profile="$(get_profile)"
  local package_type="$1"

  case "$profile" in
    minimal) [[ "$package_type" == "00_shell" ]] ;;
    server) [[ "$package_type" == "00_shell" || "$package_type" == "02_utils" ]] ;;
    full) true ;; # Install all packages
  esac
}

# Load and run packages based on profile
load_packages() {
  local package_dir="${ZSHRC_CONFIG_DIR}/packages"

  if [[ ! -d "$package_dir" ]]; then
    log_warning "Package directory not found: $package_dir"
    return 1
  fi

  # Load packages in order
  for package in "$package_dir"/*.zsh(N); do
    [[ ! -f "$package" ]] && continue

    # Extract package type from filename (e.g., "02_utils" from "02_utils_package.zsh")
    local filename="$(basename "$package")"
    local package_type="${filename%%_*}"

    if should_install_package "$package_type"; then
      log_info "Loading package: $filename"
      source "$package"
    fi
  done
}
