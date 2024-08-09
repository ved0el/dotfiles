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
  export NVM_DIR="$HOME/.nvm"
  # Suppress output by redirecting stdout and stderr to /dev/null
  {
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # Load nvm
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # Load nvm bash_completion
  } &> /dev/null
}

# Load nvm if not in VSCode
if [[ "$TERM_PROGRAM" != "vscode" ]]; then
  load_nvm
fi



# Source non-lazy configurations
source "$ZSHRC_CONFIG_DIR/nonlazy.zsh"
source "$ZSHRC_CONFIG_DIR/pluginrc/sheldon.zsh"

# Source tmux config if not in SSH session or VSCode
if [[ "$TERM_PROGRAM" != "vscode" && -z "$SSH_CONNECTION" ]]; then
  source "$ZSHRC_CONFIG_DIR/pluginrc/tmux.zsh"
fi
