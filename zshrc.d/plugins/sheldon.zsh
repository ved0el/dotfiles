#!/usr/bin/env zsh

# =============================================================================
# Sheldon Plugin Manager Configuration
# Modern ZSH plugin management with caching
# =============================================================================

# Skip if Sheldon is not installed
if ! command -v sheldon >/dev/null 2>&1; then
    echo "Warning: Sheldon not found. Install it with the dotfiles installer."
    return 1
fi

# Setup Sheldon directories
export SHELDON_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
export SHELDON_CONFIG_DIR="${DOTFILES_DIR}/config/sheldon"
export SHELDON_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon"
export SHELDON_CONFIG_FILE="${SHELDON_CONFIG_DIR}/plugins.toml"

# Create necessary directories
mkdir -p "${SHELDON_CACHE_DIR}" "${SHELDON_DATA_DIR}" 2>/dev/null

# Cache files
local sheldon_cache="${SHELDON_CACHE_DIR}/sheldon.zsh"

# Function to ensure a file is compiled with zcompile for performance
ensure_zcompiled() {
    local file="$1"
    local compiled="$file.zwc"

    if [[ ! -r "$compiled" || "$file" -nt "$compiled" ]]; then
        zcompile "$file" 2>/dev/null
    fi
}

# Regenerate cache if config is newer or cache doesn't exist
if [[ ! -r "$sheldon_cache" || "$SHELDON_CONFIG_FILE" -nt "$sheldon_cache" ]]; then
    echo "Updating Sheldon plugin cache..."
    sheldon source > "$sheldon_cache" 2>/dev/null
    ensure_zcompiled "$sheldon_cache"
fi

# Load the cached plugins
if [[ -r "$sheldon_cache" ]]; then
    source "$sheldon_cache"
else
    echo "Error: Failed to generate Sheldon cache"
    return 1
fi
