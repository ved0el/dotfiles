#!/usr/bin/env zsh

# Package management system - Optimized for fast shell startup

# Load package installer functions
if [[ -f "$DOTFILES_ROOT/zshrc.d/functions/package_installer.zsh" ]]; then
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Loading package installer"
    source "$DOTFILES_ROOT/zshrc.d/functions/package_installer.zsh"

    # Initialize packages quickly (silent mode for fast startup)
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Initializing packages"
    run_package_scripts "fast"

    # Run background updates if cache is stale (once per day)
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/package_cache"
    if [[ ! -f "$cache_file" ]] || [[ $(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) )) -gt 86400 ]]; then
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Starting background package updates"
        # Run updates in background, completely silent
        run_silent_background "run_package_scripts quiet"
        # Update cache timestamp
        mkdir -p "$(dirname "$cache_file")" 2>/dev/null
        touch "$cache_file" 2>/dev/null
    fi
else
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "⚠️  Package installer not found"
fi
