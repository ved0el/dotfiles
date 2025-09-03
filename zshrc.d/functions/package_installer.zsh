#!/usr/bin/env zsh

# =============================================================================
# Package Installation System - Clean and Simple
# =============================================================================

# -----------------------------------------------------------------------------
# Logging Functions (only used when DOTFILES_VERBOSE is set)
# -----------------------------------------------------------------------------
log_info()    { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;34m[INFO]\033[0m $1" }
log_warning() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;33m[WARNING]\033[0m $1" }
log_error()   { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;31m[ERROR]\033[0m $1" }
log_success() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "\033[1;32m[SUCCESS]\033[0m $1" }

# -----------------------------------------------------------------------------
# Platform Detection (cached)
# -----------------------------------------------------------------------------
typeset -g __ZPM_PLATFORM=""
typeset -g __ZPM_PM=""

get_platform() {
  if [[ -n "${__ZPM_PLATFORM}" ]]; then
    echo "${__ZPM_PLATFORM}"
    return 0
  fi
  case "$(uname -s)" in
    Darwin)  __ZPM_PLATFORM="macos" ;;
    Linux)   __ZPM_PLATFORM="linux" ;;
    FreeBSD) __ZPM_PLATFORM="freebsd" ;;
    *)       __ZPM_PLATFORM="unknown" ;;
  esac
  echo "${__ZPM_PLATFORM}"
}

get_package_manager() {
  if [[ -n "${__ZPM_PM}" ]]; then
    echo "${__ZPM_PM}"
    return 0
  fi
  local platform=$(get_platform)
  case "$platform" in
    macos)
      command -v brew &>/dev/null && __ZPM_PM="brew" ;;
    linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian) command -v apt &>/dev/null && __ZPM_PM="apt" ;;
          fedora|centos|rhel|rocky|alma)
            command -v dnf &>/dev/null && __ZPM_PM="dnf"
            [[ -z "$__ZPM_PM" ]] && command -v yum &>/dev/null && __ZPM_PM="yum"
            ;;
          arch|manjaro|endeavouros) command -v pacman &>/dev/null && __ZPM_PM="pacman" ;;
          opensuse|suse) command -v zypper &>/dev/null && __ZPM_PM="zypper" ;;
        esac
      fi
      ;;
    freebsd)
      command -v pkg &>/dev/null && __ZPM_PM="pkg" ;;
  esac
  [[ -z "$__ZPM_PM" ]] && __ZPM_PM="custom"
  echo "${__ZPM_PM}"
}

# -----------------------------------------------------------------------------
# Profile Management (cached)
# -----------------------------------------------------------------------------
typeset -g __ZPM_PROFILE=""
get_profile() {
  if [[ -n "${__ZPM_PROFILE}" ]]; then
    echo "${__ZPM_PROFILE}"
    return 0
  fi

  # Use the already loaded DOTFILES_PROFILE from environment/core config
  __ZPM_PROFILE="${DOTFILES_PROFILE:-minimal}"

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Using profile: $__ZPM_PROFILE"
  fi

  echo "${__ZPM_PROFILE}"
}

should_install_package() {
  local profile=$(get_profile)
  local package_type="$1"

  case "$profile" in
    minimal)
      [[ "$package_type" == "m" ]] && return 0
      ;;
    server)
      [[ "$package_type" == "m" || "$package_type" == "s" ]] && return 0
      ;;
    develop)
      [[ "$package_type" == "m" || "$package_type" == "s" || "$package_type" == "d" ]] && return 0
      ;;
  esac

  return 1
}

# -----------------------------------------------------------------------------
# Utility Functions (minimal)
# -----------------------------------------------------------------------------
is_package_installed() { command -v "$1" &>/dev/null }

# Simple compatibility shim – always use the fast path
call_install_package() { install_package_simple "$1" "$2" }

# -----------------------------------------------------------------------------
# Simple Package Installation
# -----------------------------------------------------------------------------
install_package_simple() {
  local name="$1"
  local desc="$2"

  if is_package_installed "$name"; then
    log_info "$name already installed"
    return 0
  fi

  log_info "Installing $name..."

  local pm=$(get_package_manager)
  local success=false

  case "$pm" in
    brew)
      if brew install "$name"; then
        success=true
      fi
      ;;
    apt)
      if sudo apt update && sudo apt install -y "$name"; then
        success=true
      fi
      ;;
    dnf)
      if sudo dnf install -y "$name"; then
        success=true
      fi
      ;;
    yum)
      if sudo yum install -y "$name"; then
        success=true
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm "$name"; then
        success=true
      fi
      ;;
    zypper)
      if sudo zypper install -y "$name"; then
        success=true
      fi
      ;;
    pkg)
      if sudo pkg install "$name"; then
        success=true
      fi
      ;;
  esac

  if [[ "$success" == "true" ]]; then
    log_success "$name installed successfully"
    return 0
  else
    log_error "Failed to install $name"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Unified Package Script Processing
# -----------------------------------------------------------------------------
run_package_scripts() {
  local mode="${1:-normal}"  # normal|fast|quiet
  local script_dir="$DOTFILES_ROOT/zshrc.d/packages"
  local profile=$(get_profile)

  if [[ ! -d "$script_dir" ]]; then
    [[ "$mode" == "normal" ]] && log_warning "Package scripts directory not found: $script_dir"
    return 1
  fi

  local scripts=($script_dir/*.zsh)
  if [[ ${#scripts} -eq 0 ]]; then
    [[ "$mode" == "normal" ]] && log_warning "No package scripts found in $script_dir"
    return 1
  fi

  # Sort scripts to ensure correct installation order
  scripts=("${(@n)scripts}")

  for script in "${scripts[@]}"; do
    local basename=$(basename "$script")

    # Skip template file
    if [[ "$basename" == *_template.zsh ]]; then
      continue
    fi

    # Extract package type from filename (xx_m_package.zsh -> m)
    if [[ "$basename" =~ ^[0-9]+_([msd])_.*\.zsh$ ]]; then
      local package_type=$match[1]

      if should_install_package "$package_type"; then
        # Process based on mode
        case "$mode" in
          normal)
            [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && log_info "Processing $basename..."
            source "$script"
            # Run init function if it exists
            if typeset -f init >/dev/null; then
              [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && log_info "Running init for $basename"
              init
            fi
            ;;
          fast|quiet)
            # Source silently
            source "$script" &>/dev/null 2>&1
            # Always run init function for environment setup
            if typeset -f init >/dev/null; then
              init &>/dev/null 2>&1
            fi
            ;;
        esac
      fi
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Backward Compatibility Aliases
# -----------------------------------------------------------------------------
run_package_scripts_fast() { run_package_scripts "fast"; }
run_package_scripts_quiet() { run_package_scripts "quiet"; }

# -----------------------------------------------------------------------------
# Silent background job runner (no notifications)
# -----------------------------------------------------------------------------
run_silent_background() {
  # Use a different approach: run in subshell and redirect all output
  # This completely avoids job notifications
  (
    # Run the command and redirect all output
    eval "$@" &>/dev/null
  ) &
  
  # Immediately disown the job to prevent any output
  disown $! 2>/dev/null
}
