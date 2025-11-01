#!/usr/bin/env zsh

PKG_NAME="goenv"
PKG_DESC="Go Version Manager"

is_package_installed() {
    [[ -d "${HOME}/.goenv" ]]
}

pkg_install() {
    git clone https://github.com/syndbg/goenv.git ~/.goenv
}

pkg_init() {
    [[ -f "$DOTFILES_ROOT/zshrc.d/lib/goenv_lazy.zsh" ]] && \
        source "$DOTFILES_ROOT/zshrc.d/lib/goenv_lazy.zsh"
}

init_package_template "$PKG_NAME"
