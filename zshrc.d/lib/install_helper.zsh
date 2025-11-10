#!/usr/bin/env zsh

# =============================================================================
# Package Installation Helper - Optimized for fast startup
# =============================================================================

# -----------------------------------------------------------------------------
# Color Constants (Modern, Windows Terminal compatible)
# -----------------------------------------------------------------------------
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly MAGENTA='\033[35m'
readonly CYAN='\033[36m'
readonly WHITE='\033[37m'
readonly GRAY='\033[90m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# -----------------------------------------------------------------------------
# Colored Logging Functions
# -----------------------------------------------------------------------------
_dotfiles_log_debug() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${MAGENTA}[VERBOSE]${RESET} ${GRAY}$*${RESET}"
}

_dotfiles_log_warning() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${YELLOW}[WARNING]${RESET} ${WHITE}$*${RESET}"
}

_dotfiles_log_error() {
    echo -e "${RED}[ ERROR ]${RESET} ${BOLD}${WHITE}$*${RESET}"
}

_dotfiles_log_success() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${GREEN}[SUCCESS]${RESET} ${WHITE}$*${RESET}"
}

_dotfiles_log_info() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${CYAN}[ INFO ]${RESET} ${WHITE}$*${RESET}"
}

# -----------------------------------------------------------------------------
# Package Check Function
# -----------------------------------------------------------------------------
is_package_installed() {
    local cmd_path
    cmd_path=$(command -v "$1" 2>/dev/null)
    [[ -n "$cmd_path" && -x "$cmd_path" ]]
}

# -----------------------------------------------------------------------------
# Installation Functions (OS-specific)
# -----------------------------------------------------------------------------
_dotfiles_install_package() {
    local package_name="$1"
    local package_desc="${2:-}"
  local success=false

  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
                brew install "$package_name" &>/dev/null && success=true
      fi
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
                source /etc/os-release 2>/dev/null
        case "$ID" in
          ubuntu|debian)
            if command -v apt &>/dev/null; then
                            sudo apt update &>/dev/null && \
                            sudo apt install -y "$package_name" &>/dev/null && success=true
            fi
            ;;
          fedora|centos|rhel|rocky|alma)
            if command -v dnf &>/dev/null; then
                            sudo dnf install -y "$package_name" &>/dev/null && success=true
            elif command -v yum &>/dev/null; then
                            sudo yum install -y "$package_name" &>/dev/null && success=true
            fi
            ;;
          arch|manjaro|endeavouros)
            if command -v pacman &>/dev/null; then
                            sudo pacman -S --noconfirm "$package_name" &>/dev/null && success=true
            fi
            ;;
          opensuse|suse)
            if command -v zypper &>/dev/null; then
                            sudo zypper install -y "$package_name" &>/dev/null && success=true
            fi
            ;;
        esac
      fi
      ;;
    FreeBSD)
      if command -v pkg &>/dev/null; then
                sudo pkg install -y "$package_name" &>/dev/null && success=true
      fi
      ;;
  esac

    [[ "$success" == "true" ]] && _dotfiles_log_success "$package_name is installed." && return 0
    _dotfiles_log_error "$package_name is not installed."
    return 1
}

# -----------------------------------------------------------------------------
# Main Package Lifecycle Function
# -----------------------------------------------------------------------------
init_package_template() {
    local package_name="${1:-${PKG_NAME}}"
    local package_desc="${2:-${PKG_DESC}}"
    local package_command="${3:-${PKG_CMD:-$package_name}}"

    [[ -z "$package_name" ]] && _dotfiles_log_error "Package name not provided." && return 1

    _dotfiles_log_debug "Checking $package_command..."

    # If installed, run init only
    if is_package_installed "$package_command"; then
        _dotfiles_log_debug "$package_name is installed."
        _dotfiles_log_debug "Initializing $package_name..."
        typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Initialization failed for $package_name." && return 1; }
        return $?
    fi

    # Not installed - run installation flow
    _dotfiles_log_warning "$package_name not found."

    # Pre-install
    if typeset -f pkg_pre_install >/dev/null; then
            _dotfiles_log_debug "Running pre-install for $package_name..."
            pkg_pre_install || { _dotfiles_log_error "Pre-install failed for $package_name." && return 1; }
    fi

    # Install
    if typeset -f pkg_install >/dev/null; then
        _dotfiles_log_debug "$package_name - $package_desc"
        pkg_install || _dotfiles_log_error "Installation failed for $package_name."
    else
        _dotfiles_install_package "$package_name" "$package_desc" || return 1
    fi

    # Post-install
    if typeset -f pkg_post_install >/dev/null; then
        _dotfiles_log_debug "Running post-install for $package_name..."
        pkg_post_install || _dotfiles_log_warning "Post-install failed for $package_name."
    fi

    # Initialize
    _dotfiles_log_debug "Initializing $package_name..."
    typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Initialization failed for $package_name." && return 1; }
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------
ensure_directory() {
  local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
    return $?
}

copy_if_missing() {
  local source="$1"
  local destination="$2"

  if [[ -f "$source" && ! -f "$destination" ]]; then
    cp "$source" "$destination" 2>/dev/null
    return $?
  fi
  return 0
}

create_symlink() {
  local target="$1"
  local link="$2"

    if [[ ! -e "$link" && -e "$target" ]]; then
    ln -sf "$target" "$link" 2>/dev/null
    return $?
  fi
  return 0
}
