#!/usr/bin/env zsh

PKG_NAME="goenv"
PKG_DESC="Go Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_goenv_is_installed"

_goenv_is_installed() {
    # Check both directory and binary — directory alone may exist from a broken install
    [[ -d "${HOME}/.goenv" ]] && [[ -x "${HOME}/.goenv/bin/goenv" ]]
}

pkg_install() {
    # goenv has no semver releases; pinned to a known-good HEAD commit
    # SHA verified 2026-04-03 — update when intentionally upgrading goenv
    _dotfiles_safe_git_clone \
        "https://github.com/syndbg/goenv.git" \
        "2fe3f44316262e4d4f2ca58a4b625289de2acb3f" \
        "2fe3f44316262e4d4f2ca58a4b625289de2acb3f" \
        "$HOME/.goenv"
}

pkg_init() {
    export GOENV_ROOT="${HOME}/.goenv"

    # Guard: don't re-register wrappers or prepend PATH if already loaded
    [[ "${_DOTFILES_GOENV_LOADED:-}" == "1" ]] && return 0

    # Dedup guard: only prepend if not already in PATH
    [[ ":$PATH:" == *":$GOENV_ROOT/bin:"* ]] || export PATH="$GOENV_ROOT/bin:$PATH"

    _lazy_load_goenv() {
        # Idempotency guard: extra_cmd wrappers (go, gofmt) call this on every invocation
        [[ "${_DOTFILES_GOENV_LOADED:-}" == "1" ]] && return 0
        [[ -d "$GOENV_ROOT" ]] || return 1
        [[ -f "$GOENV_ROOT/bin/goenv" ]] && eval "$(goenv init -)"
        export _DOTFILES_GOENV_LOADED="1"
    }

    create_lazy_wrapper "goenv" "_lazy_load_goenv" "go" "gofmt"
}

init_package_template "$PKG_NAME"
