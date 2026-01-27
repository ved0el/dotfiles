#!/usr/bin/env zsh

# Pyenv Lazy Loading

lazy_load_pyenv() {
    local pyenv_dir="${HOME}/.pyenv"
    [[ -d "$pyenv_dir" ]] || return 1

    export PYENV_ROOT="$pyenv_dir"

    # Add pyenv bin directory to PATH
    export PATH="$PYENV_ROOT/bin:$PATH"

    # Add shims directory to PATH (contains python, pip, etc.)
    export PATH="$PYENV_ROOT/shims:$PATH"

    # Initialize pyenv (works on both macOS and Linux)
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        return 0
    else
        return 1
    fi
}

# Only create lazy wrappers if pyenv is installed
[[ -d "${HOME}/.pyenv" ]] && [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" ]] && {
    source "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh"

    # Create wrappers for python/pip commands
    # These will automatically unfunction themselves after lazy loading
    for cmd in python python3 pip pip3; do
        eval "
${cmd}() {
    if lazy_load_pyenv; then
        # Remove this wrapper function
        unfunction ${cmd} 2>/dev/null || true
        # Run the actual command
        if command -v ${cmd} >/dev/null 2>&1; then
            command ${cmd} \"\$@\"
        else
            echo 'ERROR: ${cmd} not available after loading pyenv' >&2
            return 1
        fi
    else
        echo 'ERROR: Failed to load pyenv' >&2
        return 1
    fi
}
"
    done
}
