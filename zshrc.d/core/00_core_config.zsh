#!/usr/bin/env zsh

# Load dotfiles configuration from .zshenv
# This file is automatically managed by the dotfiles installer

# Track whether configuration was loaded from .zshenv
typeset -g DOTFILES_CONFIG_LOADED_FROM_ZSHENV=false

if [[ -f "$HOME/.zshenv" ]]; then
    # Check if .zshenv contains our required variables before sourcing
    if grep -q "^export DOTFILES_ROOT=" "$HOME/.zshenv" && \
       grep -q "^export DOTFILES_PROFILE=" "$HOME/.zshenv" && \
       grep -q "^export DOTFILES_VERBOSE=" "$HOME/.zshenv"; then

        # Source .zshenv to load existing configuration
        source "$HOME/.zshenv"
        DOTFILES_CONFIG_LOADED_FROM_ZSHENV=true

        if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
            echo "  Loading dotfiles configuration from ~/.zshenv"
        fi
    fi
fi

# Set defaults if not configured (only if not loaded from .zshenv)
if [[ "$DOTFILES_CONFIG_LOADED_FROM_ZSHENV" == "false" ]]; then
    export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
    export DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"
    export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "  Using default dotfiles configuration"
    fi
fi

# Essential environment variables
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"

# Enable verbose output during shell startup if configured
if [[ "$DOTFILES_VERBOSE" == "true" ]]; then
    echo "🔍 Verbose mode enabled - showing detailed startup information"
fi

# Startup completion message
if [[ "$DOTFILES_VERBOSE" == "true" ]]; then
    if [[ "$DOTFILES_CONFIG_LOADED_FROM_ZSHENV" == "true" ]]; then
        echo "✅ Dotfiles configuration loaded from ~/.zshenv"
    else
        echo "✅ Dotfiles configuration initialized with defaults"
    fi
    echo "   DOTFILES_ROOT: $DOTFILES_ROOT"
    echo "   DOTFILES_PROFILE: $DOTFILES_PROFILE"
    echo "   DOTFILES_VERBOSE: $DOTFILES_VERBOSE"
fi
