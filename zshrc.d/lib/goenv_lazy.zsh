#!/usr/bin/env zsh

# Goenv Lazy Loading

lazy_load_goenv() {
    local goenv_dir="${HOME}/.goenv"
    [[ -d "$goenv_dir" ]] || return 1

    export GOENV_ROOT="$goenv_dir"
    [[ -f "$goenv_dir/bin/goenv" ]] && eval "$($goenv_dir/bin/goenv init -)"
}

# Only create lazy wrappers if goenv is installed
[[ -d "${HOME}/.goenv" ]] && [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" ]] && {
    source "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh"
    create_lazy_wrapper "goenv" "lazy_load_goenv" "go" "gofmt"
}
