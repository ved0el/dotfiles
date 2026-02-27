#!/usr/bin/env zsh

PKG_NAME="tealdeer"
PKG_DESC="A very fast implementation of tldr in Rust"
PKG_CMD="tldr"

pkg_post_install() {
    command -v tldr &>/dev/null && [[ ! -f "${HOME}/.cache/tealdeer" ]] && \
        tldr --update &>/dev/null
}

pkg_init() {
    alias help="tldr"
}

init_package_template "$PKG_NAME"
