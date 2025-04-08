#!/usr/bin/env zsh

# Setup Sheldon directories
export SHELDON_CACHE_DIR="${XDG_CACHE_HOME}/sheldon"
export SHELDON_CONFIG_DIR="${XDG_CONFIG_HOME}/sheldon"
export SHELDON_DATA_DIR="${XDG_DATA_HOME}/sheldon"
export SHELDON_CONFIG_FILE="${SHELDON_CONFIG_DIR}/plugins.toml"

# Create necessary directories silently
mkdir -p "${SHELDON_CACHE_DIR}" &>/dev/null

# Cache files
sheldon_cache="${SHELDON_CACHE_DIR}/sheldon.zsh"

# Function to ensure a file is compiled with zcompile
ensure_zcompiled() {
    local file="$1"
    local compiled="$file.zwc"

    if [[ ! -r "$compiled" || "$file" -nt "$compiled" ]]; then
        zcompile "$file" &>/dev/null
    fi
}

# Generate and load cache
if [[ ! -r "$sheldon_cache" || "$SHELDON_CONFIG_FILE" -nt "$sheldon_cache" ]]; then
    sheldon source > "$sheldon_cache" 2>/dev/null
    ensure_zcompiled "$sheldon_cache"
fi

source "$sheldon_cache"
