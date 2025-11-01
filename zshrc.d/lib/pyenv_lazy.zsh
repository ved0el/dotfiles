#!/usr/bin/env zsh

# Pyenv Lazy Loading

lazy_load_pyenv() {
    local pyenv_dir="${HOME}/.pyenv"
    [[ -d "$pyenv_dir" ]] || return 1

    export PYENV_ROOT="$pyenv_dir"
    [[ -f "$pyenv_dir/bin/pyenv" ]] && eval "$($pyenv_dir/bin/pyenv init -)"
}

# Only create lazy wrappers if pyenv is installed
[[ -d "${HOME}/.pyenv" ]] && [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" ]] && {
    source "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh"
    create_lazy_wrapper "pyenv" "lazy_load_pyenv" "python" "pip" "python3" "pip3"
}
