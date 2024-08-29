#!/usr/bin/env zsh

export SHELDON_CONFIG_DIR="$XDG_CONFIG_HOME/sheldon"
export SHELDON_DATA_DIR="$XDG_DATA_HOME/sheldon"

# echo "\033[1;35mLoading\033[m sheldon config..."

# Override "source" command by adding zcompile process
source() {
  local file="$1"
  ensure_zcompiled "$file"
  builtin source "$file"
}

# Function to ensure a file is compiled with zcompile
ensure_zcompiled() {
  local file="$1"
  local compiled="$file.zwc"

  if [[ ! -r "$compiled" || "$file" -nt "$compiled" ]]; then
    zcompile "$file"
  fi
}

# Source sheldon config
plugins_toml="$SHELDON_CONFIG_DIR/plugins.toml"
sheldon_cache="$SHELDON_CONFIG_DIR/cache.zsh"

if [[ ! -r "$sheldon_cache" || "$plugins_toml" -nt "$sheldon_cache" ]]; then
  sheldon source > "$sheldon_cache"
fi
source "$sheldon_cache"
unset sheldon_cache
