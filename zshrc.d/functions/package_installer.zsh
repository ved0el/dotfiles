#!/usr/bin/env zsh

# =============================================================================
# Package Installation System
# =============================================================================

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
# Package Management
# -----------------------------------------------------------------------------
is_package_installed() {
  command -v "$1" &>/dev/null
}

# -----------------------------------------------------------------------------
# Installation Scripts Management
# -----------------------------------------------------------------------------
run_installation_scripts() {
  local script_dir="$ZSHRC_CONFIG_DIR/packages"
  local scripts=($script_dir/*.zsh)

  if [[ ${#scripts} -eq 0 ]]; then
    log_warning "No installation scripts found in $script_dir"
    return 1
  fi

  for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
      source "$script"
    else
      log_warning "Script $script is not executable"
    fi
  done
}

# -----------------------------------------------------------------------------
# Package Installation
# -----------------------------------------------------------------------------
install_package() {
  local name="$1"
  local desc="$2"
  local -A install_methods

  log_info "Installing $name - $desc"

  # Get package manager and installation command
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

  # Get and execute installation command
  local cmd="${install_methods[$pm]:-${install_methods[custom]}}"
  if [[ -z "$cmd" ]]; then
    log_error "No installation method available for $pm"
    return 1
  fi

  eval "$cmd"
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
run_installation_scripts
