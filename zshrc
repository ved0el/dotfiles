# Exported variables
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CONFIG_HOME="$DOTFILES_DIR/config"
export XDG_DATA_HOME="$DOTFILES_DIR/data"

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

# sheldon
# Fast, configurable, shell plugin manager
# https://github.com/rossmacarthur/sheldon
# Check and install "sheldon" if not installed
check_and_install_sheldon() {
  if ! command -v sheldon &> /dev/null; then
    echo "Sheldon not found. Installing..."


    # Detect current machine architecture
    if [[ "$(uname -m)" == "aarch64" ]]; then
      echo "Detected Apple Silicon architecture. Installing Sheldon via Homebrew..."
      brew install rossmacarthur/tap/sheldon
    else
      echo "Detected other architecture. Installing Sheldon via curl..."
      curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to /usr/local/bin
    fi

    if [ $? -eq 0 ]; then
      echo "Sheldon installed successfully!"
    else
      echo "Failed to install Sheldon."
      return 1
    fi
  else
    echo "Sheldon is already installed."
  fi
}


# Check and install Sheldon if not installed
check_and_install_sheldon || return 1

# Source Sheldon cache
sheldon_cache="$SHELDON_CONFIG_DIR/sheldon.zsh"
sheldon_toml="$SHOULD_CONFIG_DIR/plugins.toml"
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
  sheldon source > "$sheldon_cache"
fi
source "$sheldon_cache"
unset sheldon_cache sheldon_toml

# Source non-lazy configurations
source "$ZSH_CONFIG_DIR/nonlazy.zsh"

# Source lazy configurations using zsh-defer
zsh-defer source "$ZSH_CONFIG_DIR/lazy.zsh"
zsh-defer unfunction source

# Install nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash_completion

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
