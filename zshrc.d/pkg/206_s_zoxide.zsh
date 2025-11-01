#!/usr/bin/env zsh

PKG_NAME="zoxide"
PKG_DESC="A smarter cd command"

pkg_init() {
    eval "$(zoxide init zsh)"
    alias cd="z"
    alias cdi="zi"
    export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 --group-directories-first --header --no-user --no-time --no-filesize --no-permissions {2..}' --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."
}

init_package_template "$PKG_NAME"
