#!/usr/bin/env zsh

# Fast dotfiles configuration loading
# Optimized for minimal startup time

# Set defaults immediately (no file checks for speed)
export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
export DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

# Essential environment variables (minimal set)
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"

# Only show verbose output if explicitly enabled
[[ "$DOTFILES_VERBOSE" == "true" ]] && echo "🔍 Verbose mode enabled"
