#!/usr/bin/env zsh

# =============================================================================
# Platform detection — OS, distro, and package manager
# Values are cached after first call (stable per session, safe to cache).
# =============================================================================

# Returns: macos | linux | freebsd | unknown
dotfiles_os() {
    if [[ -z "${_DOTFILES_OS_CACHE:-}" ]]; then
        case "$(uname -s)" in
            Darwin)  _DOTFILES_OS_CACHE="macos" ;;
            Linux)   _DOTFILES_OS_CACHE="linux" ;;
            FreeBSD) _DOTFILES_OS_CACHE="freebsd" ;;
            *)       _DOTFILES_OS_CACHE="unknown" ;;
        esac
    fi
    echo "$_DOTFILES_OS_CACHE"
}

# Returns: distro ID from /etc/os-release, or 'unknown' (Linux only)
dotfiles_distro() {
    if [[ -z "${_DOTFILES_DISTRO_CACHE:-}" ]]; then
        if [[ "$(dotfiles_os)" != "linux" ]]; then
            _DOTFILES_DISTRO_CACHE="unknown"
        else
            local id=""
            [[ -f /etc/os-release ]] && id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
            _DOTFILES_DISTRO_CACHE="${id:-unknown}"
        fi
    fi
    echo "$_DOTFILES_DISTRO_CACHE"
}

# Returns: brew | apt | dnf | yum | pacman | zypper | pkg | unknown
dotfiles_pkg_manager() {
    if [[ -n "${_DOTFILES_PKG_MGR_CACHE:-}" ]]; then
        echo "$_DOTFILES_PKG_MGR_CACHE"
        return
    fi

    local os id id_like result="unknown"
    os="$(dotfiles_os)"

    case "$os" in
        macos)
            command -v brew &>/dev/null && result="brew" ;;
        freebsd)
            command -v pkg &>/dev/null && result="pkg" ;;
        linux)
            # Source /etc/os-release once for both ID and ID_LIKE
            if [[ -f /etc/os-release ]]; then
                id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
                id_like=$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")
            fi
            # Check exact distro ID first
            case "$id" in
                ubuntu|debian|raspbian|linuxmint|pop)
                    command -v apt &>/dev/null && result="apt" ;;
                fedora|centos|rhel|rocky|alma)
                    command -v dnf &>/dev/null && result="dnf" || \
                    command -v yum &>/dev/null && result="yum" ;;
                arch|manjaro|endeavouros)
                    command -v pacman &>/dev/null && result="pacman" ;;
                opensuse*|suse)
                    command -v zypper &>/dev/null && result="zypper" ;;
            esac
            # Fallback to ID_LIKE for derivative distros
            # (e.g. Raspbian: ID=raspbian ID_LIKE=debian)
            if [[ "$result" == "unknown" ]]; then
                case "$id_like" in
                    *debian*|*ubuntu*)
                        command -v apt &>/dev/null && result="apt" ;;
                    *rhel*|*fedora*)
                        command -v dnf &>/dev/null && result="dnf" || \
                        command -v yum &>/dev/null && result="yum" ;;
                    *arch*)
                        command -v pacman &>/dev/null && result="pacman" ;;
                    *suse*)
                        command -v zypper &>/dev/null && result="zypper" ;;
                esac
            fi ;;
    esac

    _DOTFILES_PKG_MGR_CACHE="$result"
    echo "$result"
}
