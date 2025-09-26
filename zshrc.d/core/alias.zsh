#!/usr/bin/env zsh

# =============================================================================
# Shell Aliases
# Modern command replacements and convenience shortcuts
# =============================================================================

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# List directory contents with modern tools
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -l --icons --group-directories-first --time-style=long-iso"
    alias la="eza -la --icons --group-directories-first --time-style=long-iso"
    alias tree="eza --tree --icons"
else
    alias ll="ls -alF"
    alias la="ls -A"
    alias l="ls -CF"
fi

# Modern command replacements
if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
    alias catn="bat --style=plain"  # plain cat without line numbers
fi

if command -v fd >/dev/null 2>&1; then
    alias find="fd"
fi

if command -v rg >/dev/null 2>&1; then
    alias grep="rg"
fi

if command -v zoxide >/dev/null 2>&1; then
    alias cd="z"
fi

# Git shortcuts
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias glog="git log --oneline --graph --decorate"

# System
alias reload="exec ${SHELL} -l"
alias edit-zsh="$EDITOR ~/.zshrc"
alias edit-config="$EDITOR $DOTFILES_DIR"

# Network
alias myip="curl -s https://ipinfo.io/ip"
alias localip="ipconfig getifaddr en0"

# Utilities
alias h="history"
alias j="jobs"
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# Safety nets
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Directory shortcuts
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias docs="cd ~/Documents"

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}