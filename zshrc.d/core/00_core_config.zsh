#!/usr/bin/env zsh

# Fast dotfiles configuration loading
# Optimized for minimal startup time


# Load configuration from .zshenv if it exists
if [[ -f "$HOME/.zshenv" ]]; then
    source "$HOME/.zshenv" 2>/dev/null || true
fi

# Set defaults immediately (no file checks for speed)
export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
export DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

# Suppress tool warnings immediately (after setting defaults)
if [[ "$DOTFILES_VERBOSE" != "true" ]]; then
    export _ZO_DOCTOR=0  # Suppress zoxide warnings
    export ZSH_DISABLE_COMPFIX=true  # Suppress zsh completion warnings
    export DISABLE_AUTO_UPDATE=true  # Suppress oh-my-zsh update warnings
    export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true  # Suppress p10k warnings
fi

# Essential environment variables (minimal set)
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"

# Additional performance optimizations
if [[ "$DOTFILES_VERBOSE" != "true" ]]; then
    # Disable slow shell features
    export ZSH_DISABLE_COMPFIX=true
    export DISABLE_AUTO_UPDATE=true
    export DISABLE_MAGIC_FUNCTIONS=true
    export DISABLE_LS_COLORS=true
    export DISABLE_AUTO_TITLE=true
    export DISABLE_UNTRACKED_FILES_DIRTY=true
    
    # Fast directory operations
    export DIRSTACKSIZE=0
    
    # Disable slow completion features
    export ZSH_AUTOSUGGEST_USE_ASYNC=true
    export ZSH_AUTOSUGGEST_MANUAL_REBIND=true
fi

# Suppress job control notifications unless in debug mode
if [[ "$DOTFILES_VERBOSE" != "true" ]]; then
    # Disable job control notifications
    setopt NO_NOTIFY
    # Suppress background job output
    setopt NO_BG_NICE
    # Suppress completion messages
    setopt NO_LIST_BEEP
    # Suppress error messages for non-existent commands
    setopt NO_CORRECT_ALL
fi

# Function to suppress output unless in debug mode
suppress_output() {
    if [[ "$DOTFILES_VERBOSE" != "true" ]]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

# Only show verbose output if explicitly enabled
[[ "$DOTFILES_VERBOSE" == "true" ]] && echo "🔍 Verbose mode enabled"

