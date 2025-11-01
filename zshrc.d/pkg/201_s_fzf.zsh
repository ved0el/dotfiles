#!/usr/bin/env zsh

PKG_NAME="fzf"
PKG_DESC="A command-line fuzzy finder"

pkg_init() {
    export FZF_DEFAULT_COMMAND="fd --type f"
    export FZF_DEFAULT_OPTS="--height 75% --multi --reverse"
    export FZF_COMPLETION_TRIGGER=''
    export FZF_COMPLETION_OPTS=''
}

init_package_template "$PKG_NAME"
