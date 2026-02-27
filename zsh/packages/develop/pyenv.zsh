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
        [[ -d "$PYENV_ROOT" ]] || return 1
        # Add shims to PATH (contains python, pip, etc.)
        export PATH="$PYENV_ROOT/shims:$PATH"
        command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
    }

    # Create self-destructing wrappers for python/pip commands
    local _cmd
    for _cmd in python python3 pip pip3; do
        eval "
${_cmd}() {
    if _lazy_load_pyenv; then
        unfunction ${_cmd} 2>/dev/null || true
        if command -v ${_cmd} >/dev/null 2>&1; then
            command ${_cmd} \"\$@\"
        else
            echo 'ERROR: ${_cmd} not available after loading pyenv' >&2
            return 1
        fi
    else
        echo 'ERROR: Failed to load pyenv' >&2
        return 1
    fi
}
"
    done
    unset _cmd
}

init_package_template "$PKG_NAME"
