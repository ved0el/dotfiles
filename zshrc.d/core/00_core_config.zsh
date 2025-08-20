#!/usr/bin/env zsh

# Load dotfiles configuration from .zshenv
# This file is automatically managed by the dotfiles installer
if [[ -f "$HOME/.zshenv" ]]; then
    # Source .zshenv first to get DOTFILES_VERBOSE
    source "$HOME/.zshenv"
    
    # Now check verbose mode after sourcing
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "  Loading dotfiles configuration from ~/.zshenv"
    fi
fi

# Set defaults if not configured
export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
export DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

# Essential environment variables
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"

# Enable verbose output during shell startup if configured
if [[ "$DOTFILES_VERBOSE" == "true" ]]; then
    echo "🔍 Verbose mode enabled - showing detailed startup information"
fi

# Startup completion message
if [[ "$DOTFILES_VERBOSE" == "true" ]]; then
    echo "✅ Dotfiles configuration loaded successfully"
    echo "   Profile: $DOTFILES_PROFILE"
    echo "   Root: $DOTFILES_ROOT"
fi
