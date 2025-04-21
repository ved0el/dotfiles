#!/usr/bin/env zsh

# Setup Sheldon directories
export SHELDON_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
export SHELDON_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon"
export SHELDON_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon"
export SHELDON_CONFIG_FILE="${SHELDON_CONFIG_DIR}/plugins.toml"

# Create necessary directories silently
mkdir -p "${SHELDON_CACHE_DIR}" &>/dev/null

# Cache files
sheldon_cache="${SHELDON_CACHE_DIR}/cache.zsh"


# Generate and load cache
if [[ ! -r "$sheldon_cache" || "$SHELDON_CONFIG_FILE" -nt "$sheldon_cache" ]]; then
    sheldon source > "$sheldon_cache" 2>/dev/null
fi

ensure_zcompiled "$sheldon_cache"
unset sheldon_cache
