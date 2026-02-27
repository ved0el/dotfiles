#!/usr/bin/env zsh

# =============================================================================
# Package lifecycle engine — check, warn, install, init
# =============================================================================

# Color constants (guard against re-sourcing)
if [[ ! -v _DOTFILES_COLORS_LOADED ]]; then
    readonly RED='\033[31m'     GREEN='\033[32m'   YELLOW='\033[33m'
    readonly BLUE='\033[34m'    MAGENTA='\033[35m' CYAN='\033[36m'
    readonly WHITE='\033[37m'   GRAY='\033[90m'    BOLD='\033[1m'
    readonly RESET='\033[0m'
    readonly _DOTFILES_COLORS_LOADED=1
fi

# -----------------------------------------------------------------------------
# Logging — only debug/info/warning/success shown when VERBOSE=true
# -----------------------------------------------------------------------------
_dotfiles_log_debug()   { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${MAGENTA}[VERBOSE]${RESET} ${GRAY}$*${RESET}"; }
_dotfiles_log_info()    { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${CYAN}[ INFO ]${RESET} ${WHITE}$*${RESET}"; }
_dotfiles_log_warning() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${YELLOW}[WARNING]${RESET} ${WHITE}$*${RESET}"; }
_dotfiles_log_success() { [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo -e "${GREEN}[SUCCESS]${RESET} ${WHITE}$*${RESET}"; }
_dotfiles_log_error()   { echo -e "${RED}[ ERROR ]${RESET} ${BOLD}${WHITE}$*${RESET}" >&2; }

# -----------------------------------------------------------------------------
# Package check
# -----------------------------------------------------------------------------
is_package_installed() {
    local cmd_path
    cmd_path=$(command -v "$1" 2>/dev/null)
    [[ -n "$cmd_path" && -x "$cmd_path" ]]
}

# -----------------------------------------------------------------------------
# OS-aware package installer (delegates to detected package manager)
# Falls back to pkg_install_fallback() if distro is unknown
# -----------------------------------------------------------------------------
_dotfiles_install_package() {
    local package_name="$1"
    local package_desc="${2:-}"
    local pkg_mgr
    pkg_mgr="$(dotfiles_pkg_manager)"

    _dotfiles_log_info "Installing ${package_name} via ${pkg_mgr}..."

    local success=false
    case "$pkg_mgr" in
        brew)
            brew install "$package_name" && success=true ;;
        apt)
            sudo apt-get update -qq && sudo apt-get install -y "$package_name" && success=true ;;
        dnf)
            sudo dnf install -y "$package_name" && success=true ;;
        yum)
            sudo yum install -y "$package_name" && success=true ;;
        pacman)
            sudo pacman -S --noconfirm "$package_name" && success=true ;;
        zypper)
            sudo zypper install -y "$package_name" && success=true ;;
        pkg)
            sudo pkg install -y "$package_name" && success=true ;;
        unknown)
            if typeset -f pkg_install_fallback >/dev/null; then
                _dotfiles_log_info "No known package manager. Trying pkg_install_fallback..."
                pkg_install_fallback && success=true
            else
                local distro
                distro="$(dotfiles_distro)"
                _dotfiles_log_error "Cannot auto-install ${package_name} on ${distro}. Install manually, then re-run."
                return 1
            fi ;;
    esac

    if [[ "$success" == "true" ]]; then
        _dotfiles_log_success "${package_name} installed successfully"
        return 0
    else
        _dotfiles_log_error "Failed to install ${package_name}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# _dotfiles_check_installed — unified check using PKG_CHECK_FUNC or binary
# -----------------------------------------------------------------------------
_dotfiles_check_installed() {
    local pkg_cmd="$1"
    if [[ -n "${PKG_CHECK_FUNC:-}" ]] && typeset -f "${PKG_CHECK_FUNC}" >/dev/null; then
        "${PKG_CHECK_FUNC}"
    elif [[ -n "$pkg_cmd" ]]; then
        is_package_installed "$pkg_cmd"
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Package lifecycle orchestrator
# Usage: init_package_template "$PKG_NAME"
# Reads package variables: PKG_NAME, PKG_DESC, PKG_CMD, PKG_CHECK_FUNC
# Calls hook functions if defined: pkg_pre_install, pkg_install,
#   pkg_install_fallback, pkg_post_install, pkg_init
# -----------------------------------------------------------------------------
init_package_template() {
    local package_name="${1:-${PKG_NAME}}"
    local package_desc="${PKG_DESC:-}"
    local package_command="${PKG_CMD:-$package_name}"

    [[ -z "$package_name" ]] && _dotfiles_log_error "Package name not provided" && return 1

    _dotfiles_log_debug "Checking ${package_name}..."

    # Check if installed
    if _dotfiles_check_installed "$package_command"; then
        _dotfiles_log_debug "${package_name} is installed ✓"
        if typeset -f pkg_init >/dev/null; then
            pkg_init || { _dotfiles_log_error "Failed to initialize ${package_name}"; return 1; }
        fi
        _dotfiles_log_success "${package_name} initialized"
        return 0
    fi

    # Not installed — warn on normal startup, full install when VERBOSE=true
    if [[ "${DOTFILES_VERBOSE:-false}" != "true" ]]; then
        echo "[dotfiles] ${package_name} not installed — run: dotfiles install" >&2
        return 0
    fi

    # Full install flow (DOTFILES_VERBOSE=true)
    echo
    _dotfiles_log_warning "${package_name} not found — ${package_desc}"
    _dotfiles_log_info "Attempting to install ${package_name}..."

    if typeset -f pkg_pre_install >/dev/null; then
        pkg_pre_install || { _dotfiles_log_error "Pre-install failed for ${package_name}"; return 1; }
    fi

    if typeset -f pkg_install >/dev/null; then
        pkg_install || { _dotfiles_log_error "Installation failed for ${package_name}"; return 1; }
    else
        _dotfiles_install_package "$package_name" "$package_desc" || \
            { _dotfiles_log_error "Installation failed for ${package_name}"; return 1; }
    fi

    # Re-verify after install
    if ! _dotfiles_check_installed "$package_command"; then
        _dotfiles_log_error "${package_name} installation completed but not found"
        return 1
    fi

    if typeset -f pkg_post_install >/dev/null; then
        pkg_post_install || _dotfiles_log_warning "Post-install failed for ${package_name}"
    fi

    if typeset -f pkg_init >/dev/null; then
        pkg_init || { _dotfiles_log_error "Failed to initialize ${package_name}"; return 1; }
    fi

    _dotfiles_log_success "${package_name} installed and initialized ✓"
    echo
    return 0
}

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------
ensure_directory() {
    [[ -d "$1" ]] || mkdir -p "$1" 2>/dev/null
}

copy_if_missing() {
    [[ -f "$1" && ! -f "$2" ]] && cp "$1" "$2" 2>/dev/null
    return 0
}

create_symlink() {
    [[ ! -e "$2" && -e "$1" ]] && ln -sf "$1" "$2" 2>/dev/null
    return 0
}
