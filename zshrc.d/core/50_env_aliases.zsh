#!/usr/bin/env zsh

# Essential environment variables and PATH setup
[[ ":$PATH:" != *":$DOTFILES_ROOT/bin:"* ]] && export PATH="$PATH:$DOTFILES_ROOT/bin"
[[ -d "$HOME/.local/bin" ]] && export PATH="$PATH:$HOME/.local/bin"

# Performance optimizations
export NVM_LAZY_LOAD="true"
export POWERLEVEL9K_INSTANT_PROMPT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache/p10k}"

# Essential aliases for fast navigation
alias zshsrc="source ~/.zshrc"
alias zshedit="$EDITOR ~/.zshrc"

