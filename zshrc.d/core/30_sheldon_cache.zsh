#!/usr/bin/env zsh

# Fast Sheldon plugin loading with caching
if command -v sheldon &>/dev/null; then
    local sheldon_cache="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon/cache.zsh"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/sheldon" &>/dev/null

    # Check cache validity (1 hour)
    if [[ -r "$sheldon_cache" ]] && (( $(date +%s) - $(stat -f %m "$sheldon_cache" 2>/dev/null || echo 0) < 3600 )); then
        # Use cached plugins
        source "$sheldon_cache" &>/dev/null
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Sheldon plugins loaded from cache"
    else
        # Update cache and load
        sheldon lock --update &>/dev/null 2>&1
        sheldon source > "${sheldon_cache}.tmp" 2>/dev/null && mv "${sheldon_cache}.tmp" "$sheldon_cache" &>/dev/null 2>&1
        [[ -r "$sheldon_cache" ]] && source "$sheldon_cache" &>/dev/null
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Sheldon cache updated"
    fi
else
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "⚠️ Sheldon not found"
fi
