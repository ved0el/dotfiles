#!/usr/bin/env zsh

# Ultra-fast Sheldon preloader with verbose support
if command -v sheldon &>/dev/null; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Loading Sheldon plugins from cache"
    fi
    
    local sheldon_cache="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon/cache.zsh"
    local sheldon_config="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"

    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/sheldon" &>/dev/null

    if [[ -r "$sheldon_cache" ]]; then
        # Cross-platform stat command detection
        local cache_age=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS/BSD
            cache_age=$(( $(date +%s) - $(stat -f %m "$sheldon_cache" 2>/dev/null || echo 0) ))
        else
            # Linux/GNU
            cache_age=$(( $(date +%s) - $(stat -c %Y "$sheldon_cache" 2>/dev/null || echo 0) ))
        fi
        
        if (( cache_age < 3600 )); then
            source "$sheldon_cache" &>/dev/null
        else
            source "$sheldon_cache" &>/dev/null
            # Run sheldon operations synchronously to avoid background jobs
            if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
                echo "✅ Updating Sheldon cache (cache age: ${cache_age}s)"
            fi
            sheldon lock --update &>/dev/null 2>&1
            sheldon source > "${sheldon_cache}.tmp" 2>/dev/null && mv "${sheldon_cache}.tmp" "$sheldon_cache" &>/dev/null 2>&1
        fi
    else
        # Run sheldon operations synchronously to avoid background jobs
        if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
            echo "✅ Creating Sheldon cache"
        fi
        sheldon lock --update &>/dev/null 2>&1
        sheldon source > "${sheldon_cache}.tmp" 2>/dev/null && mv "${sheldon_cache}.tmp" "$sheldon_cache" &>/dev/null 2>&1
    fi
else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "⚠️ Sheldon not found, skipping plugin loading"
    fi
fi
