#!/usr/bin/env zsh

# =============================================================================
# Platform detection — OS, distro, and package manager
# =============================================================================

# Returns: macos | linux | freebsd | unknown
dotfiles_os() {
    case "$(uname -s)" in
        Darwin)  echo "macos" ;;
        Linux)   echo "linux" ;;
        FreeBSD) echo "freebsd" ;;
        *)       echo "unknown" ;;
    esac
}

# Returns: distro ID from /etc/os-release, or 'unknown' (Linux only)
dotfiles_distro() {
    [[ "$(dotfiles_os)" != "linux" ]] && echo "unknown" && return
    local id=""
    [[ -f /etc/os-release ]] && id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
    echo "${id:-unknown}"
}

# Returns: brew | apt | dnf | yum | pacman | zypper | pkg | unknown
dotfiles_pkg_manager() {
    local os id id_like
    os="$(dotfiles_os)"

    case "$os" in
        macos)
            command -v brew &>/dev/null && echo "brew" || echo "unknown"
            return ;;
        freebsd)
            command -v pkg &>/dev/null && echo "pkg" || echo "unknown"
            return ;;
        linux)
            if [[ -f /etc/os-release ]]; then
                id=$(. /etc/os-release 2>/dev/null; echo "${ID:-}")
                id_like=$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")
            fi
            # Check exact ID first
            case "$id" in
                ubuntu|debian|raspbian|linuxmint|pop)
                    command -v apt &>/dev/null && echo "apt" && return ;;
                fedora|centos|rhel|rocky|alma)
                    command -v dnf &>/dev/null && echo "dnf" && return
                    command -v yum &>/dev/null && echo "yum" && return ;;
                arch|manjaro|endeavouros)
                    command -v pacman &>/dev/null && echo "pacman" && return ;;
                opensuse*|suse)
                    command -v zypper &>/dev/null && echo "zypper" && return ;;
            esac
            # Fallback: check ID_LIKE for derivative distros
            # (e.g. Raspbian: ID=raspbian ID_LIKE=debian; Mint: ID=linuxmint ID_LIKE=ubuntu)
            case "$id_like" in
                *debian*|*ubuntu*)
                    command -v apt &>/dev/null && echo "apt" && return ;;
                *rhel*|*fedora*)
                    command -v dnf &>/dev/null && echo "dnf" && return
                    command -v yum &>/dev/null && echo "yum" && return ;;
                *arch*)
                    command -v pacman &>/dev/null && echo "pacman" && return ;;
                *suse*)
                    command -v zypper &>/dev/null && echo "zypper" && return ;;
            esac
            echo "unknown" ;;
        *)
            echo "unknown" ;;
    esac
}
