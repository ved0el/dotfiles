#!/usr/bin/env zsh

# =============================================================================
# Package Installation System
# =============================================================================

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly DEFAULT_PROFILE="minimal"

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------
log_info()    { echo -e "\033[1;34m[INFO]\033[0m $1" }
log_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1" }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" }

# -----------------------------------------------------------------------------
# Package Manager Detection
# -----------------------------------------------------------------------------
get_package_manager() {
  case "$(uname -s)" in
    Darwin)
      command -v brew &>/dev/null && { echo "brew"; return 0 }
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian) command -v apt &>/dev/null && { echo "apt"; return 0 } ;;
          fedora|centos|rhel)
            command -v dnf &>/dev/null && { echo "dnf"; return 0 }
            command -v yum &>/dev/null && { echo "yum"; return 0 }
            ;;
          arch|manjaro) command -v pacman &>/dev/null && { echo "pacman"; return 0 } ;;
        esac
      fi
      ;;
  esac
  echo "custom"
  return 1
}

# -----------------------------------------------------------------------------
# Profile Management
# -----------------------------------------------------------------------------
get_profile() {
  # Try current environment first
  local profile="${DOTFILES_PROFILE:-}"

  # Try loading from zshenv if not set
  if [[ -z "$profile" && -f "$HOME/.zshenv" ]]; then
    source "$HOME/.zshenv"
    profile="${DOTFILES_PROFILE:-}"
  fi

  # Return profile or default
  echo "${profile:-$DEFAULT_PROFILE}"
}

should_install_package() {
  local package_type="$1"
  local profile=$(get_profile)

  case "$profile" in
    full)
      # Install everything in full profile
      return 0
      ;;
    server)
      # Install shell and utils, but not dev tools
      [[ "$package_type" =~ ^(00_shell|02_utils) ]] && return 0
      ;;
    minimal)
      # Install shell (except tmux) and utils
      if [[ "$package_type" =~ ^(00_shell|02_utils) ]]; then
        [[ "$package_type" == *"tmux"* ]] && return 1
        return 0
      fi
      ;;
  esac
  return 1
}

# -----------------------------------------------------------------------------
# Package Management
# -----------------------------------------------------------------------------
is_package_installed() {
  command -v "$1" &>/dev/null
}

is_dependency_installed() {
  local deps=($1)  # Split into array automatically in zsh

  # Skip if no deps
  [[ -z "$deps" ]] && return 0

  # Check each dependency
  for dep in $deps; do
    if ! is_package_installed "$dep"; then
      log_warning "Missing required dependencies: $dep"
      return 1
    fi
  done

  return 0
}

install_package() {
  local name="$1"
  local desc="$2"
  local -A install_methods

  log_info "Installing $name - $desc"

  # Get package manager
  local pm=$(get_package_manager)

  # Process installation methods
  shift 2
  local key value
  while (( $# > 0 )); do
    key="$1"
    value="$2"
    install_methods[$key]="$value"
    shift 2
  done

  # Get installation command
  local cmd="${install_methods[$pm]:-${install_methods[custom]}}"
  if [[ -z "$cmd" ]]; then
    log_error "No installation method available for $pm"
    return 1
  fi

  # Execute installation
  eval "$cmd" || {
    log_error "Failed to install $name"
    return 1
  }
  log_success "Installed $name successfully"
}

# -----------------------------------------------------------------------------
# Installation Scripts Management
# -----------------------------------------------------------------------------
run_installation_scripts() {
  local script_dir="$ZSHRC_CONFIG_DIR/packages"
  local scripts=($script_dir/*.zsh)
  local profile=$(get_profile)

  if [[ ${#scripts} -eq 0 ]]; then
    log_warning "No installation scripts found in $script_dir"
    return 1
  fi


  # Sort scripts to ensure correct installation order
  scripts=("${(@n)scripts}")

  for script in "${scripts[@]}"; do
    # Skip non-executable scripts
    if [[ ! -x "$script" ]]; then
      log_warning "Script not executable: $script"
      continue
    fi

    local basename=$(basename "$script")
    local package_type="${basename%_*}"  # Get prefix (00_shell, 01_dev, 02_utils)

    # Check if package should be installed for current profile
    if should_install_package "$basename"; then
      source "$script" && ((count++))
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
run_installation_scripts
