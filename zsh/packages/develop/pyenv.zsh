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

    _lazy_load_pyenv() {
        # Idempotency guard — shims already in PATH means pyenv is loaded
        [[ "$PATH" == *"$PYENV_ROOT/shims"* ]] && return 0
        [[ -d "$PYENV_ROOT" ]] || return 1
        export PATH="$PYENV_ROOT/shims:$PATH"
        command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
    }

    create_lazy_wrapper "pyenv" "_lazy_load_pyenv" "python" "python3" "pip" "pip3"
}

init_package_template "$PKG_NAME"
