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
    # Clone directly via git — avoids curl|bash and is pinned by git's TLS/integrity
    git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
}

pkg_init() {
    export PYENV_ROOT="${HOME}/.pyenv"

    # Guard: don't re-register wrappers or prepend PATH if already loaded
    [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0

    # Dedup guard: only prepend if not already in PATH
    [[ ":$PATH:" == *":$PYENV_ROOT/bin:"* ]] || export PATH="$PYENV_ROOT/bin:$PATH"

    _lazy_load_pyenv() {
        # Idempotency guard: extra_cmd wrappers (python, pip, etc.) call this on every invocation
        [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0
        [[ -d "$PYENV_ROOT" ]] || return 1
        [[ ":$PATH:" == *":$PYENV_ROOT/shims:"* ]] || export PATH="$PYENV_ROOT/shims:$PATH"
        command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
        export _DOTFILES_PYENV_LOADED="1"
    }

    create_lazy_wrapper "pyenv" "_lazy_load_pyenv" "python" "python3" "pip" "pip3"
}

init_package_template "$PKG_NAME"
