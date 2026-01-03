#!/usr/bin/env zsh

export TERM="xterm-256color"

# Essential environment variables and PATH setup
[[ ":$PATH:" != *":$DOTFILES_ROOT/bin:"* ]] && export PATH="$PATH:$DOTFILES_ROOT/bin"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$PATH:$HOME/.local/bin"

# Performance optimizations
export NVM_LAZY_LOAD="true"
export POWERLEVEL9K_INSTANT_PROMPT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache/p10k}"
