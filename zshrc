# Exported variables
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CONFIG_HOME="$DOTFILES_DIR/config"
export XDG_DATA_HOME="$DOTFILES_DIR/data"
export ZSHRC_CONFIG_DIR="$DOTFILES_DIR/zshrc.d"

# Check if $DOTFILES_DIR/bin is in $PATH
if [[ ":$PATH:" != *":$DOTFILES_DIR/bin:"* ]]; then
  export PATH="$PATH:$DOTFILES_DIR/bin"
fi

# Source non-lazy configurations
source "$ZSHRC_CONFIG_DIR/nonlazy.zsh"
source "$ZSHRC_CONFIG_DIR/pluginrc/sheldon.zsh"

export NVM_DIR="$HOME/.dotfiles/data/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
