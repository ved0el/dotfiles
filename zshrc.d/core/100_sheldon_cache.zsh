#!/usr/bin/env zsh

# Fast Sheldon plugin loading with caching (prefer immediate load, refresh async)
_dotfiles_load_sheldon_cache() {
    if command -v sheldon &>/dev/null; then
        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
        local sheldon_cache="${cache_dir}/cache.zsh"
        local sheldon_cache_tmp="${sheldon_cache}.tmp"
        local sheldon_plugins_file="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
        local now_ts
        local cache_mtime
        local plugins_mtime
        local max_age=${DOTFILES_SHELDON_CACHE_MAX_AGE:-21600}  # default 6h

        mkdir -p "$cache_dir" &>/dev/null

        now_ts=$(date +%s)
        cache_mtime=$(stat -f %m "$sheldon_cache" 2>/dev/null || echo 0)
        plugins_mtime=$(stat -f %m "$sheldon_plugins_file" 2>/dev/null || echo 0)

        # First-run: build cache synchronously once (quiet), then source
        if [[ ! -r "$sheldon_cache" ]]; then
            if [[ -r "$sheldon_plugins_file" ]]; then
                sheldon lock &>/dev/null 2>&1
            fi
            sheldon source > "$sheldon_cache_tmp" 2>/dev/null && mv "$sheldon_cache_tmp" "$sheldon_cache" &>/dev/null 2>&1
            [[ -r "$sheldon_cache" ]] && source "$sheldon_cache" &>/dev/null
            return 0
        fi

        # Normal path: load cache immediately (quiet)
        source "$sheldon_cache" &>/dev/null

        # If stale by age or plugins changed, refresh in background (quiet)
        if [[ $(( now_ts - cache_mtime )) -ge $max_age || $plugins_mtime -gt $cache_mtime ]]; then
            (
                if command -v sheldon &>/dev/null; then
                    if [[ $plugins_mtime -gt $cache_mtime && -r "$sheldon_plugins_file" ]]; then
                        sheldon lock &>/dev/null 2>&1
                    fi
                    sheldon source > "$sheldon_cache_tmp" 2>/dev/null && mv "$sheldon_cache_tmp" "$sheldon_cache" &>/dev/null 2>&1
                fi
            ) & disown
        fi
    fi
}
