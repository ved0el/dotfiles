#!/usr/bin/env zsh

# =============================================================================
# Package Installation System - Clean Architecture
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
typeset -g PACKAGE_INSTALLER_VERSION="2.0.0"
typeset -g PACKAGE_INSTALLER_DEBUG="${DOTFILES_VERBOSE:-false}"

# -----------------------------------------------------------------------------
# Enhanced Logging System
# -----------------------------------------------------------------------------
typeset -g LOG_LEVEL="${DOTFILES_VERBOSE:-false}"
typeset -g LOG_TIMESTAMP=false

# Logging functions with levels and timestamps
log_info()    { [[ "$LOG_LEVEL" == "true" ]] && echo -e "\033[1;34m[INFO]\033[0m $(get_timestamp)$1" }
log_warning() { [[ "$LOG_LEVEL" == "true" ]] && echo -e "\033[1;33m[WARNING]\033[0m $(get_timestamp)$1" }
log_error()   { [[ "$LOG_LEVEL" == "true" ]] && echo -e "\033[1;31m[ERROR]\033[0m $(get_timestamp)$1" }
log_success() { [[ "$LOG_LEVEL" == "true" ]] && echo -e "\033[1;32m[SUCCESS]\033[0m $(get_timestamp)$1" }
log_debug()   { [[ "$LOG_LEVEL" == "true" ]] && echo -e "\033[0;90m[DEBUG]\033[0m $(get_timestamp)$1" }

# Get timestamp for logging
get_timestamp() {
  if [[ "$LOG_TIMESTAMP" == "true" ]]; then
    echo "[$(date '+%H:%M:%S')] "
  else
    echo ""
  fi
}

# Enhanced logging with context
log_with_context() {
  local level="$1"
  local context="$2"
  local message="$3"
  
  case "$level" in
    info)    log_info "[$context] $message" ;;
    warning) log_warning "[$context] $message" ;;
    error)   log_error "[$context] $message" ;;
    success) log_success "[$context] $message" ;;
    debug)   log_debug "[$context] $message" ;;
  esac
}

# Performance logging
log_performance() {
  local start_time="$1"
  local operation="$2"
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  if [[ "$LOG_LEVEL" == "true" ]]; then
    log_debug "Performance: $operation completed in ${duration}s"
  fi
}

# -----------------------------------------------------------------------------
# Platform Detection (cached)
# -----------------------------------------------------------------------------
typeset -g __PLATFORM=""
typeset -g __PACKAGE_MANAGER=""

get_platform() {
  [[ -n "$__PLATFORM" ]] && { echo "$__PLATFORM"; return 0; }
  
  case "$(uname -s)" in
    Darwin)  __PLATFORM="macos" ;;
    Linux)   __PLATFORM="linux" ;;
    FreeBSD) __PLATFORM="freebsd" ;;
    *)       __PLATFORM="unknown" ;;
  esac
  
  log_debug "Detected platform: $__PLATFORM"
  echo "$__PLATFORM"
}

get_package_manager() {
  [[ -n "$__PACKAGE_MANAGER" ]] && { echo "$__PACKAGE_MANAGER"; return 0; }
  
  local platform=$(get_platform)
  case "$platform" in
    macos)
      command -v brew &>/dev/null && __PACKAGE_MANAGER="brew" ;;
    linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian) command -v apt &>/dev/null && __PACKAGE_MANAGER="apt" ;;
          fedora|centos|rhel|rocky|alma)
            command -v dnf &>/dev/null && __PACKAGE_MANAGER="dnf"
            [[ -z "$__PACKAGE_MANAGER" ]] && command -v yum &>/dev/null && __PACKAGE_MANAGER="yum"
            ;;
          arch|manjaro|endeavouros) command -v pacman &>/dev/null && __PACKAGE_MANAGER="pacman" ;;
          opensuse|suse) command -v zypper &>/dev/null && __PACKAGE_MANAGER="zypper" ;;
        esac
      fi
      ;;
    freebsd)
      command -v pkg &>/dev/null && __PACKAGE_MANAGER="pkg" ;;
  esac
  
  [[ -z "$__PACKAGE_MANAGER" ]] && __PACKAGE_MANAGER="custom"
  log_debug "Detected package manager: $__PACKAGE_MANAGER"
  echo "$__PACKAGE_MANAGER"
}

# -----------------------------------------------------------------------------
# Profile Management (cached)
# -----------------------------------------------------------------------------
typeset -g __PROFILE=""

get_profile() {
  [[ -n "$__PROFILE" ]] && { echo "$__PROFILE"; return 0; }
  
  __PROFILE="${DOTFILES_PROFILE:-minimal}"
  log_debug "Using profile: $__PROFILE"
  echo "$__PROFILE"
}

should_install_package() {
  local profile=$(get_profile)
  local package_type="$1"

  case "$profile" in
    minimal)  [[ "$package_type" == "m" ]] && return 0 ;;
    server)   [[ "$package_type" == "m" || "$package_type" == "s" ]] && return 0 ;;
    develop)  [[ "$package_type" == "m" || "$package_type" == "s" || "$package_type" == "d" ]] && return 0 ;;
  esac

  return 1
}

# -----------------------------------------------------------------------------
# Core Utilities & Error Handling
# -----------------------------------------------------------------------------
is_package_installed() { command -v "$1" &>/dev/null }

# Error handling utilities
handle_error() {
  local error_msg="$1"
  local exit_code="${2:-1}"
  log_error "$error_msg"
  return $exit_code
}

validate_environment() {
  local errors=0
  
  # Check required environment variables
  [[ -z "$DOTFILES_ROOT" ]] && { log_error "DOTFILES_ROOT not set"; ((errors++)); }
  [[ -z "$DOTFILES_PROFILE" ]] && { log_error "DOTFILES_PROFILE not set"; ((errors++)); }
  
  # Check if DOTFILES_ROOT exists
  [[ ! -d "$DOTFILES_ROOT" ]] && { log_error "DOTFILES_ROOT directory not found: $DOTFILES_ROOT"; ((errors++)); }
  
  # Validate profile
  case "$DOTFILES_PROFILE" in
    minimal|server|develop) ;;
    *) log_error "Invalid profile: $DOTFILES_PROFILE"; ((errors++)); ;;
  esac
  
  return $errors
}

# Safe command execution with error handling
safe_exec() {
  local cmd="$1"
  local description="${2:-Command execution}"
  
  log_debug "Executing: $description"
  
  if eval "$cmd" 2>/dev/null; then
    log_debug "Success: $description"
    return 0
  else
    log_error "Failed: $description"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Package Installation Engine
# -----------------------------------------------------------------------------
install_package() {
  local name="$1"
  local desc="${2:-$name}"
  
  # Validate input
  [[ -z "$name" ]] && { handle_error "Package name is required"; return 1; }
  
  if is_package_installed "$name"; then
    log_debug "$name already installed"
    return 0
  fi

  log_info "Installing $name..."
  
  local pm=$(get_package_manager)
  local install_cmd=""
  
  # Build installation command based on package manager
  case "$pm" in
    brew)     install_cmd="brew install $name" ;;
    apt)      install_cmd="sudo apt update && sudo apt install -y $name" ;;
    dnf)      install_cmd="sudo dnf install -y $name" ;;
    yum)      install_cmd="sudo yum install -y $name" ;;
    pacman)   install_cmd="sudo pacman -S --noconfirm $name" ;;
    zypper)   install_cmd="sudo zypper install -y $name" ;;
    pkg)      install_cmd="sudo pkg install $name" ;;
    *)        handle_error "Unsupported package manager: $pm"; return 1 ;;
  esac
  
  # Execute installation with error handling
  if safe_exec "$install_cmd" "Install $name via $pm"; then
    # Verify installation
    if is_package_installed "$name"; then
      log_success "$name installed successfully"
      return 0
    else
      handle_error "Installation verification failed for $name"
      return 1
    fi
  else
    handle_error "Failed to install $name"
    return 1
  fi
}

# Backward compatibility
install_package_simple() { install_package "$1" "$2" }
call_install_package() { install_package "$1" "$2" }

# -----------------------------------------------------------------------------
# Package Script Processing Engine
# -----------------------------------------------------------------------------
run_package_scripts() {
  local mode="${1:-normal}"  # normal|fast|quiet
  local script_dir="${DOTFILES_ROOT}/zshrc.d/packages"
  local profile=$(get_profile)
  local processed=0
  local failed=0
  local start_time=$(date +%s)

  log_with_context "info" "PACKAGE_SCRIPTS" "Starting package processing (mode: $mode, profile: $profile)"

  # Validate environment first
  if ! validate_environment; then
    handle_error "Environment validation failed"
    return 1
  fi

  # Validate script directory
  if [[ ! -d "$script_dir" ]]; then
    handle_error "Package scripts directory not found: $script_dir"
    return 1
  fi

  # Get and sort scripts
  local scripts=($script_dir/*.zsh)
  if [[ ${#scripts} -eq 0 ]]; then
    log_warning "No package scripts found in $script_dir"
    return 1
  fi
  scripts=("${(@n)scripts}")

  log_with_context "debug" "PACKAGE_SCRIPTS" "Found ${#scripts[@]} package scripts for profile: $profile"

  for script in "${scripts[@]}"; do
    local basename=$(basename "$script")
    local script_start_time=$(date +%s)
    
    # Skip template files
    [[ "$basename" == *template* ]] && continue
    
    # Extract package type from filename (xx_m_package.zsh -> m)
    if [[ "$basename" =~ ^[0-9]+_([msd])_.*\.zsh$ ]]; then
      local package_type=$match[1]
      
      if should_install_package "$package_type"; then
        log_with_context "debug" "PACKAGE_SCRIPTS" "Processing $basename (type: $package_type)"
        
        # Use enhanced processing function with error handling
        if process_package_script "$script" "$mode"; then
          ((processed++))
          log_performance "$script_start_time" "Process $basename"
        else
          log_with_context "warning" "PACKAGE_SCRIPTS" "Failed to process $basename"
          ((failed++))
        fi
      else
        log_with_context "debug" "PACKAGE_SCRIPTS" "Skipping $basename (not required for profile: $profile)"
      fi
    else
      log_with_context "debug" "PACKAGE_SCRIPTS" "Skipping $basename (invalid filename format)"
    fi
  done

  log_performance "$start_time" "Package processing"
  log_with_context "info" "PACKAGE_SCRIPTS" "Processing complete: $processed processed, $failed failed"
  
  # Return error if any packages failed
  if (( failed > 0 )); then
    log_with_context "warning" "PACKAGE_SCRIPTS" "$failed package(s) failed to process"
    return 1
  fi
  
  return 0
}

# -----------------------------------------------------------------------------
# Backward Compatibility & Utilities
# -----------------------------------------------------------------------------
run_package_scripts_fast() { run_package_scripts "fast"; }
run_package_scripts_quiet() { run_package_scripts "quiet"; }

# Silent background execution
run_silent_background() {
  (eval "$@" &>/dev/null) & disown $! 2>/dev/null
}

# Package validation
validate_package_script() {
  local script="$1"
  [[ -f "$script" ]] || return 1
  [[ "$(basename "$script")" =~ ^[0-9]+_[msd]_.*\.zsh$ ]] || return 1
  return 0
}

# Get package info from script
get_package_info() {
  local script="$1"
  local name="" desc="" deps="" type=""
  
  if [[ -f "$script" ]]; then
    name=$(grep -E '^PACKAGE_NAME=' "$script" 2>/dev/null | cut -d'"' -f2)
    desc=$(grep -E '^PACKAGE_DESC=' "$script" 2>/dev/null | cut -d'"' -f2)
    deps=$(grep -E '^PACKAGE_DEPS=' "$script" 2>/dev/null | cut -d'"' -f2)
    type=$(grep -E '^PACKAGE_TYPE=' "$script" 2>/dev/null | cut -d'"' -f2)
  fi
  
  echo "${name:-unknown}|${desc:-No description}|${deps:-none}|${type:-standard}"
}

# -----------------------------------------------------------------------------
# Cleanup and Rollback Mechanisms
# -----------------------------------------------------------------------------

# Cleanup temporary files and caches
cleanup_temp_files() {
  local cleaned=0
  
  # Clean up temporary files
  for pattern in "/tmp/dotfiles-*" "/tmp/package-*" "/tmp/install-*"; do
    if ls $pattern &>/dev/null; then
      rm -f $pattern
      ((cleaned++))
    fi
  done
  
  # Clean up zsh cache files
  for pattern in "*.zwc" "*.zwc.old"; do
    if ls $pattern &>/dev/null; then
      rm -f $pattern
      ((cleaned++))
    fi
  done
  
  log_debug "Cleaned up $cleaned temporary files"
  return 0
}

# Rollback failed package installation
rollback_package() {
  local package_name="$1"
  local pm=$(get_package_manager)
  
  log_debug "Attempting to rollback $package_name"
  
  case "$pm" in
    brew)
      brew uninstall "$package_name" &>/dev/null || true
      ;;
    apt)
      sudo apt remove -y "$package_name" &>/dev/null || true
      ;;
    dnf)
      sudo dnf remove -y "$package_name" &>/dev/null || true
      ;;
    yum)
      sudo yum remove -y "$package_name" &>/dev/null || true
      ;;
    pacman)
      sudo pacman -R --noconfirm "$package_name" &>/dev/null || true
      ;;
    zypper)
      sudo zypper remove -y "$package_name" &>/dev/null || true
      ;;
    pkg)
      sudo pkg delete "$package_name" &>/dev/null || true
      ;;
  esac
  
  log_debug "Rollback completed for $package_name"
  return 0
}

# Cleanup function for package installer
cleanup_package_installer() {
  log_debug "Cleaning up package installer"
  
  # Clean up temporary files
  cleanup_temp_files
  
  # Reset global variables
  __PLATFORM=""
  __PACKAGE_MANAGER=""
  __PROFILE=""
  
  log_debug "Package installer cleanup completed"
  return 0
}

# Enhanced package processing with template support
process_package_script() {
  local script="$1"
  local mode="${2:-normal}"
  
  # Validate script
  if ! validate_package_script "$script"; then
    log_debug "Invalid package script: $script"
    return 1
  fi
  
  local basename=$(basename "$script")
  log_debug "Processing package: $basename"
  
  # Source the script with error handling
  if source "$script" 2>/dev/null; then
    # Run init function if it exists
    if typeset -f init >/dev/null; then
      if [[ "$mode" == "normal" ]]; then
        if ! init; then
          log_warning "Init function failed for $basename"
          return 1
        fi
      else
        init &>/dev/null 2>&1
      fi
    fi
    return 0
  else
    log_error "Failed to source $basename"
    return 1
  fi
}
