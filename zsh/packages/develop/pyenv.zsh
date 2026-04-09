#!/usr/bin/env zsh

PKG_NAME="pyenv"
PKG_DESC="Python Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_pyenv_is_installed"

_pyenv_is_installed() {
    # Check both directory and binary — directory alone may exist from a broken install
    [[ -d "${HOME}/.pyenv" ]] && [[ -x "${HOME}/.pyenv/bin/pyenv" ]]
}

pkg_install() {
    # Pinned to v2.6.13 — update tag+SHA together when bumping
    # Commit SHA verified 2026-04-03
    _dotfiles_safe_git_clone \
        "https://github.com/pyenv/pyenv.git" \
        "v2.6.13" \
        "fdde91269b95bd8a61e9f8d11cba9a1e2de038ad" \
        "$HOME/.pyenv"
}

pkg_init() {
    export PYENV_ROOT="${HOME}/.pyenv"

    # Guard: don't re-register wrappers or prepend PATH if already loaded
    [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0

    # Dedup guard: only prepend if not already in PATH
    [[ ":$PATH:" == *":$PYENV_ROOT/bin:"* ]] || export PATH="$PYENV_ROOT/bin:$PATH"

    _lazy_load_pyenv() {
        [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0
        # Set flag early to prevent re-entry from extra_cmd wrappers (python, pip)
        _DOTFILES_PYENV_LOADED="1"
        if [[ ! -d "$PYENV_ROOT" ]]; then
            unset _DOTFILES_PYENV_LOADED; return 1
        fi
        [[ ":$PATH:" == *":$PYENV_ROOT/shims:"* ]] || export PATH="$PYENV_ROOT/shims:$PATH"
        [[ -x "$PYENV_ROOT/bin/pyenv" ]] && eval "$("$PYENV_ROOT/bin/pyenv" init -)"
    }

    create_lazy_wrapper "pyenv" "_lazy_load_pyenv" "python" "python3" "pip" "pip3"
}

init_package_template "$PKG_NAME"
