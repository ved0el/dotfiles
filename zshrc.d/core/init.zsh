#!/usr/bin/env zsh

# =============================================================================
# ZSH Initialization
# Core shell configuration and setup
# =============================================================================

# Enable color support
autoload -U colors && colors

# Enable completion system
autoload -Uz compinit

# Load version control info functions
autoload -Uz vcs_info

# Enable command substitution in prompts
setopt PROMPT_SUBST

# Load additional completion definitions
fpath=("$DOTFILES_DIR/completions" $fpath)

# Initialize completion system with security checks disabled for performance
if [[ $# -gt 0 ]]; then
    compinit
else
    compinit -C
fi

# Load bash completion compatibility
autoload -U +X bashcompinit && bashcompinit

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
