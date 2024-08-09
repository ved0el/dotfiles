#!/usr/bin/env zsh

export SHELDON_CONFIG_DIR="$XDG_CONFIG_HOME/sheldon"
export SHELDON_DATA_DIR="$XDG_DATA_HOME/sheldon"

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
    echo "\033[1;36mCompiling\033[m $file"
    zcompile "$file"
  fi
}

# Replace placeholders in plugins.toml with environment variable values
plugins_toml="$SHELDON_CONFIG_DIR/plugins.toml"
temp_plugins_toml="/tmp/plugins.toml"

# Ensure proper quoting for paths and use 'sed' to replace placeholders
sed -e "s|{{DOTFILES_DIR}}|$DOTFILES_DIR|g" "$plugins_toml" > "$temp_plugins_toml"

# Source Sheldon cache
sheldon_cache="$SHELDON_CONFIG_DIR/cache.zsh"
if [[ ! -r "$sheldon_cache" || "$temp_plugins_toml" -nt "$sheldon_cache" ]]; then
  sheldon source > "$sheldon_cache"
fi
source "$sheldon_cache"
unset sheldon_cache

# Clean up temporary file
rm "$temp_plugins_toml"
