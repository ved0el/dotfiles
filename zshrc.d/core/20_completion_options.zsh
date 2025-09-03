#!/usr/bin/env zsh

# Fast completion initialization with caching
autoload -Uz compinit

# Use cached completion if available, otherwise regenerate
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+1) ]]; then
    compinit
else
    compinit -C
fi

# Minimal completion styles for fast performance
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# zstyle ':completion:*' verbose no
# zstyle ':completion:*' show-completer no
# zstyle ':completion:*' file-sort name
# zstyle ':completion:*' file-list all
# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# zstyle ':completion:*' completer _complete
# zstyle ':completion:*' max-errors 0

# zstyle ':completion:*' list-ambiguous no
# zstyle ':completion:*' list-packed no
# zstyle ':completion:*' list-rows-first no
# zstyle ':completion:*' list-types no
# zstyle ':completion:*' menu no
# zstyle ':completion:*' select no
