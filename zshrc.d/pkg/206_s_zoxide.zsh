#!/usr/bin/env zsh

PKG_NAME="zoxide"
PKG_DESC="A smarter cd command"

pkg_init() {
    eval "$(zoxide init zsh)"
    alias cd="z"
    alias cdi="zi"
}

init_package_template "$PKG_NAME"
