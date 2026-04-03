#!/usr/bin/env zsh

PKG_NAME="pyenv"
PKG_DESC="Python Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_pyenv_is_installed"

_pyenv_is_installed() {
    [[ -d "${HOME}/.pyenv" ]]
}

pkg_install() {
    curl https://pyenv.run | bash
}

pkg_init() {
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    # Guard: don't re-register wrappers if already loaded (e.g. source ~/.zshrc)
    [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0

    _lazy_load_pyenv() {
        # Idempotency guard: extra_cmd wrappers (python, pip, etc.) call this on every invocation
        [[ "${_DOTFILES_PYENV_LOADED:-}" == "1" ]] && return 0
        [[ -d "$PYENV_ROOT" ]] || return 1
        export PATH="$PYENV_ROOT/shims:$PATH"
        command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
        export _DOTFILES_PYENV_LOADED="1"
    }

    create_lazy_wrapper "pyenv" "_lazy_load_pyenv" "python" "python3" "pip" "pip3"
}

init_package_template "$PKG_NAME"
