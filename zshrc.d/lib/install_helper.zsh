#!/usr/bin/env zsh

# =============================================================================
# Package Installation Helper - Optimized for fast startup
# =============================================================================

# -----------------------------------------------------------------------------
# Color Constants (Modern, Windows Terminal compatible)
# -----------------------------------------------------------------------------
# Only set if not already readonly (allows re-sourcing without errors)
[[ -v RED ]] || readonly RED='\033[31m'
[[ -v GREEN ]] || readonly GREEN='\033[32m'
[[ -v YELLOW ]] || readonly YELLOW='\033[33m'
[[ -v BLUE ]] || readonly BLUE='\033[34m'
[[ -v MAGENTA ]] || readonly MAGENTA='\033[35m'
[[ -v CYAN ]] || readonly CYAN='\033[36m'
[[ -v WHITE ]] || readonly WHITE='\033[37m'
[[ -v GRAY ]] || readonly GRAY='\033[90m'
[[ -v BOLD ]] || readonly BOLD='\033[1m'
[[ -v RESET ]] || readonly RESET='\033[0m'

# -----------------------------------------------------------------------------
# Colored Logging Functions
# -----------------------------------------------------------------------------
# Debug: Only shown when verbose is on
_dotfiles_log_debug() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${MAGENTA}[VERBOSE]${RESET} ${GRAY}$*${RESET}"
}

# Warning: Only shown when verbose is on
_dotfiles_log_warning() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${YELLOW}[WARNING]${RESET} ${WHITE}$*${RESET}"
}

# Error: ALWAYS shown (regardless of verbose setting)
_dotfiles_log_error() {
    echo -e "${RED}[ ERROR ]${RESET} ${BOLD}${WHITE}$*${RESET}" >&2
}

# Success: Only shown when verbose is on
_dotfiles_log_success() {
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${GREEN}[SUCCESS]${RESET} ${WHITE}$*${RESET}"
}

# Info: Only shown when verbose is on
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
    local os_type=$(uname -s)

    _dotfiles_log_info "Installing $package_name via system package manager..."

    case "$os_type" in
        Darwin)
            if command -v brew &>/dev/null; then
                _dotfiles_log_debug "Using Homebrew..."
                if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
                    brew install "$package_name" && success=true
                else
                    brew install "$package_name" &>/dev/null && success=true
                fi
            else
                _dotfiles_log_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release 2>/dev/null
                case "$ID" in
                    ubuntu|debian)
                        if command -v apt &>/dev/null; then
                            _dotfiles_log_debug "Using apt package manager..."
                            sudo apt update &>/dev/null && \
                            sudo apt install -y "$package_name" && success=true
                        fi
                        ;;
                    fedora|centos|rhel|rocky|alma)
                        if command -v dnf &>/dev/null; then
                            _dotfiles_log_debug "Using dnf package manager..."
                            sudo dnf install -y "$package_name" && success=true
                        elif command -v yum &>/dev/null; then
                            _dotfiles_log_debug "Using yum package manager..."
                            sudo yum install -y "$package_name" && success=true
                        fi
                        ;;
                    arch|manjaro|endeavouros)
                        if command -v pacman &>/dev/null; then
                            _dotfiles_log_debug "Using pacman package manager..."
                            sudo pacman -S --noconfirm "$package_name" && success=true
                        fi
                        ;;
                    opensuse|suse)
                        if command -v zypper &>/dev/null; then
                            _dotfiles_log_debug "Using zypper package manager..."
                            sudo zypper install -y "$package_name" && success=true
                        fi
                        ;;
                    *)
                        _dotfiles_log_error "Unsupported Linux distribution: $ID"
                        return 1
                        ;;
                esac
            else
                _dotfiles_log_error "Cannot detect Linux distribution"
                return 1
            fi
            ;;
        FreeBSD)
            if command -v pkg &>/dev/null; then
                _dotfiles_log_debug "Using FreeBSD pkg..."
                sudo pkg install -y "$package_name" && success=true
            else
                _dotfiles_log_error "FreeBSD pkg not found"
                return 1
            fi
            ;;
        *)
            _dotfiles_log_error "Unsupported operating system: $os_type"
            return 1
            ;;
    esac

    if [[ "$success" == "true" ]]; then
        _dotfiles_log_success "$package_name installed successfully"
        return 0
    else
        _dotfiles_log_error "Failed to install $package_name"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main Package Lifecycle Function
# -----------------------------------------------------------------------------
init_package_template() {
    local package_name="${1:-${PKG_NAME}}"
    local package_desc="${2:-${PKG_DESC}}"
    local package_command="${3:-${PKG_CMD:-$package_name}}"

    [[ -z "$package_name" ]] && _dotfiles_log_error "Package name not provided" && return 1

    _dotfiles_log_debug "Checking $package_command..."

    # If installed, run init only
    if is_package_installed "$package_command"; then
        _dotfiles_log_debug "$package_name is already installed ✓"
        _dotfiles_log_debug "Initializing $package_name..."
        typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Failed to initialize $package_name" && return 1; }
        _dotfiles_log_success "$package_name initialized successfully"
        return 0
    fi

    # Not installed - only attempt installation if verbose mode is on (dotfiles commands)
    # During normal shell startup (verbose=false), skip silently
    if [[ "${DOTFILES_VERBOSE:-false}" != "true" ]]; then
        _dotfiles_log_debug "$package_name not installed, skipping..."
        return 0
    fi

    # Installation flow (only runs when verbose=true, i.e., during dotfiles commands)
    echo
    _dotfiles_log_warning "$package_name not found - $package_desc"
    _dotfiles_log_info "Attempting to install $package_name..."

    # Pre-install
    if typeset -f pkg_pre_install >/dev/null; then
            _dotfiles_log_debug "Running pre-install for $package_name..."
            pkg_pre_install || { _dotfiles_log_error "Pre-install failed for $package_name" && return 1; }
    fi

    # Install
    if typeset -f pkg_install >/dev/null; then
        _dotfiles_log_debug "Installing $package_name..."
        pkg_install || { _dotfiles_log_error "Installation failed for $package_name" && return 1; }
    else
        _dotfiles_install_package "$package_name" "$package_desc" || { _dotfiles_log_error "Installation failed for $package_name" && return 1; }
    fi

    # Verify installation
    if ! is_package_installed "$package_command"; then
        _dotfiles_log_error "$package_name installation completed but command not found"
        return 1
    fi

    # Post-install
    if typeset -f pkg_post_install >/dev/null; then
        _dotfiles_log_debug "Running post-install for $package_name..."
        pkg_post_install || _dotfiles_log_warning "Post-install failed for $package_name"
    fi

    # Initialize
    _dotfiles_log_debug "Initializing $package_name..."
    typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Failed to initialize $package_name" && return 1; }

    _dotfiles_log_success "$package_name installed and initialized successfully ✓"
    echo
    return 0
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
