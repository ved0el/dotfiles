#!/usr/bin/env zsh

PKG_NAME="bat"
PKG_DESC="A cat clone with syntax highlighting and Git integration"

pkg_post_install() {
    # Ubuntu/Debian ships bat as 'batcat' — create a compat symlink
    [[ "$(uname -s)" == "Linux" ]] && ! command -v batcat &>/dev/null && \
        create_symlink "$(command -v bat)" "/usr/local/bin/batcat"
}

pkg_init() {
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
}

init_package_template "$PKG_NAME"
