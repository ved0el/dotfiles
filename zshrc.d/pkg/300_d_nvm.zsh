#!/usr/bin/env zsh

PKG_NAME="nvm"
PKG_DESC="Node Version Manager"

is_package_installed() {
    [[ -d "${HOME}/.nvm" ]]
}

pkg_install() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
}

pkg_init() {
    [[ -f "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh" ]] && \
        source "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh"
}

init_package_template "$PKG_NAME"
