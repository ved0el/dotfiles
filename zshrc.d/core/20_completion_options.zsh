# #!/usr/bin/env zsh

# # Fast completion init with verbose support
# if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
#   echo "✅ Initializing completion system"
# fi

# autoload -Uz compinit
# if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+1) ]]; then
#     compinit
# else
#     compinit -C
# fi

# # Minimal completion styles for fast performance
# zstyle ':completion:*' accept-exact '*(N)'
# zstyle ':completion:*' use-cache on
# zstyle ':completion:*' cache-path ~/.zsh/cache
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' group-name ''
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
