#!/usr/bin/env zsh

PKG_DESC="A simple, fast and user-friendly alternative to find"

pkg_pre_install() {
    # Ubuntu/Debian names the package 'fd-find'
    if [[ "$(dotfiles_pkg_manager)" == "apt" ]]; then
        PKG_NAME="fd-find"
        PKG_CMD="fd"
    fi
}

pkg_post_install() {
    # Ubuntu/Debian names the binary 'fdfind' — create a 'fd' compat symlink
    if [[ "$(uname -s)" == "Linux" ]] && command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
}

pkg_init() {
    export FD_OPTIONS="--follow --exclude .git --exclude node_modules"
}

init_package_template "fd"
