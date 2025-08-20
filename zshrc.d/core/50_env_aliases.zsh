#!/usr/bin/env zsh

# Essential environment and aliases with verbose support
if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    echo "✅ Setting up environment and aliases"
fi

# Add dotfiles bin to PATH if not already there
if [[ ":$PATH:" != *":$DOTFILES_ROOT/bin:"* ]]; then
    export PATH="$PATH:$DOTFILES_ROOT/bin"
fi

# Add local bin to PATH if directory exists
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Performance optimizations
export NVM_LAZY_LOAD="true"
export POWERLEVEL9K_INSTANT_PROMPT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache/p10k}"

# Essential aliases for fast navigation
alias zshsrc="source ~/.zshrc"
alias zshedit="$EDITOR ~/.zshrc"
# alias cd="z"  # Commented out to allow regular cd with fzf completion
alias ..="z .."
alias ...="z ../.."
alias ....="z ../../.."

# Lightweight git aliases when in git repository (fast check)
if [[ -d .git ]]; then
    alias gst="git status"
    alias gco="git checkout"
    alias gb="git branch"
    alias gp="git push"
    alias gl="git pull"
    alias gd="git diff"
    alias ga="git add"
    alias gc="git commit"
    alias gcm="git commit -m"
fi
