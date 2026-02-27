#!/usr/bin/env zsh

PKG_NAME="bat"
PKG_DESC="A cat clone with syntax highlighting and Git integration"

pkg_post_install() {
    # Ubuntu/Debian names the binary 'batcat' — create a 'bat' compat symlink
    if [[ "$(uname -s)" == "Linux" ]] && command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
}

pkg_init() {
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
}

init_package_template "$PKG_NAME"
