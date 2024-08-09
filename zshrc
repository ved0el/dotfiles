# Exported variables
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CONFIG_HOME="$DOTFILES_DIR/config"
export XDG_DATA_HOME="$DOTFILES_DIR/data"
export ZSHRC_CONFIG_DIR="$DOTFILES_DIR/zshrc.d"

# Ensure DOTFILES_DIR/bin is in PATH
if ! command -v "$DOTFILES_DIR/bin" &> /dev/null; then
  export PATH="$PATH:$DOTFILES_DIR/bin"
fi

# Function to load nvm
load_nvm() {
  export NVM_DIR="$HOME/.dotfiles/data/nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # Load nvm
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # Load nvm bash_completion
}

# Load nvm if not in VSCode
if [[ "$TERM_PROGRAM" != "vscode" ]]; then
  load_nvm > /dev/null 2>&1
fi

# Source non-lazy configurations
source "$ZSHRC_CONFIG_DIR/nonlazy.zsh"
source "$ZSHRC_CONFIG_DIR/pluginrc/sheldon.zsh"

# Source tmux config if not in SSH session or VSCode
if [[ "$TERM_PROGRAM" != "vscode" && -z "$SSH_CONNECTION" ]]; then
  source "$ZSHRC_CONFIG_DIR/pluginrc/tmux.zsh"
fi
