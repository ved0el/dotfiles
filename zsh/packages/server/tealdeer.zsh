#!/usr/bin/env zsh

PKG_NAME="tealdeer"
PKG_DESC="A very fast implementation of tldr in Rust"
PKG_CMD="tldr"

pkg_post_install() {
    # Populate the cache on first install (tealdeer cache is a directory, not a file)
    command -v tldr &>/dev/null && tldr --update &>/dev/null
}

pkg_init() {
    alias help="tldr"
}

init_package_template "$PKG_NAME"
