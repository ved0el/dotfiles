#!/usr/bin/env zsh

PKG_NAME="vfox"
PKG_DESC="Universal version manager for Node.js, Python, Go, and more"

pkg_install() {
    local os="$(dotfiles_os)"
    local pkg_mgr="$(dotfiles_pkg_manager)"

    if [[ "$os" == "macos" ]] && [[ "$pkg_mgr" == "brew" ]]; then
        brew install vfox || return 1
    elif [[ "$pkg_mgr" == "apt" ]]; then
        echo "deb [trusted=yes lang=none] https://apt.fury.io/versionfox/ /" | sudo tee /etc/apt/sources.list.d/versionfox.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y vfox || return 1
    else
        curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/version-fox/vfox/main/install.sh | bash || return 1
    fi
}

pkg_init() {
    # Guard: don't re-activate vfox if already loaded (e.g. source ~/.zshrc)
    [[ "${_DOTFILES_VFOX_LOADED:-}" == "1" ]] && return 0

    eval "$(vfox activate zsh)"

    export _DOTFILES_VFOX_LOADED="1"
}

init_package_template "$PKG_NAME"
