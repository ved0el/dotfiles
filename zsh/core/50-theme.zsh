#!/usr/bin/env zsh

# =============================================================================
# Powerlevel10k theme
# Instant prompt must load before any output is produced.
# =============================================================================

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

# Powerlevel10k instant prompt (must load before theme and any output)
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh" ]] && \
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k/p10k-instant-prompt-${(%):-%n}.zsh"

# Load Powerlevel10k theme configuration
if [[ -r ~/.p10k.zsh ]]; then
    source ~/.p10k.zsh
elif [[ -r "$DOTFILES_ROOT/p10k.zsh" ]]; then
    source "$DOTFILES_ROOT/p10k.zsh"
else
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "Warning: p10k.zsh not found" >&2
fi
