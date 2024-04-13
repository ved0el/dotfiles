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

# Source Sheldon cache
sheldon_cache="$SHELDON_CONFIG_DIR/cache.zsh"
sheldon_toml="$SHOULD_CONFIG_DIR/plugins.toml"
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
  sheldon source > "$sheldon_cache"
fi
source "$sheldon_cache"
unset sheldon_cache sheldon_toml

# Source lazy configurations using zsh-defer
zsh-defer source "$ZSH_CONFIG_DIR/lazy.zsh"
zsh-defer unfunction source
