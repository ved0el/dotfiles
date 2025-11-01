#!/usr/bin/env zsh

PKG_NAME="pyenv"
PKG_DESC="Python Version Manager"

is_package_installed() {
    [[ -d "${HOME}/.pyenv" ]]
}

pkg_install() {
    curl https://pyenv.run | bash
}

pkg_init() {
    [[ -f "$DOTFILES_ROOT/zshrc.d/lib/pyenv_lazy.zsh" ]] && \
        source "$DOTFILES_ROOT/zshrc.d/lib/pyenv_lazy.zsh"
}

init_package_template "$PKG_NAME"
