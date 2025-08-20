#!/usr/bin/env zsh

# Package management system
# This script handles package installation and updates efficiently

# Load package installer functions
if [[ -f "$DOTFILES_ROOT/zshrc.d/functions/package_installer.zsh" ]]; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Sourcing package installer functions"
    fi
    source "$DOTFILES_ROOT/zshrc.d/functions/package_installer.zsh"

    # Process package scripts to initialize installed packages (optimized mode)
    # Use fast mode for immediate shell startup, then quick silent updates
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Running package scripts"
    fi
    run_package_scripts_fast &>/dev/null 2>&1

    # Run quick updates if needed (synchronous but fast)
    # Only run heavy operations if cache is old
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/package_cache"
    if [[ ! -f "$cache_file" ]] || [[ $(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) )) -gt 86400 ]]; then
        if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
            echo "✅ Running background package updates..."
        fi
        # Run updates quickly and silently in background
        (run_package_scripts_quiet &>/dev/null 2>&1) &
        disown $! 2>/dev/null
        # Update cache
        mkdir -p "$(dirname "$cache_file")" 2>/dev/null
        touch "$cache_file" 2>/dev/null
    fi
else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "⚠️  Package installer not found: $DOTFILES_ROOT/zshrc.d/functions/package_installer.zsh"
    fi
fi
