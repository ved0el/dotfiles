#!/usr/bin/env zsh

PKG_NAME="goenv"
PKG_DESC="Go Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_goenv_is_installed"

_goenv_is_installed() {
    [[ -d "${HOME}/.goenv" ]]
}

pkg_install() {
    git clone https://github.com/syndbg/goenv.git ~/.goenv
}

pkg_init() {
    export GOENV_ROOT="${HOME}/.goenv"

    # Guard: don't re-register wrappers if already loaded (e.g. source ~/.zshrc)
    [[ "${_DOTFILES_GOENV_LOADED:-}" == "1" ]] && return 0

    _lazy_load_goenv() {
        # Idempotency guard: extra_cmd wrappers (go, gofmt) call this on every invocation
        [[ "${_DOTFILES_GOENV_LOADED:-}" == "1" ]] && return 0
        [[ -d "$GOENV_ROOT" ]] || return 1
        export PATH="$GOENV_ROOT/bin:$PATH"
        [[ -f "$GOENV_ROOT/bin/goenv" ]] && eval "$(goenv init -)"
        export _DOTFILES_GOENV_LOADED="1"
    }

    create_lazy_wrapper "goenv" "_lazy_load_goenv" "go" "gofmt"
}

init_package_template "$PKG_NAME"
