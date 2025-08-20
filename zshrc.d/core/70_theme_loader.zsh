#!/usr/bin/env zsh

# Powerlevel10k minimal fast config
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=false
typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096
typeset -g POWERLEVEL9K_VCS_STAGED_MAX_NUM=10
typeset -g POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM=10
typeset -g POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM=10
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

# Enable Powerlevel10k instant prompt (must be first)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Loading Powerlevel10k instant prompt"
    fi
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Load Powerlevel10k theme
if [[ -f ~/.p10k.zsh ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Loading Powerlevel10k theme"
    fi
    source ~/.p10k.zsh
fi
