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
