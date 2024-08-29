# Exported variables
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CONFIG_HOME="$DOTFILES_DIR/config"
export XDG_DATA_HOME="$DOTFILES_DIR/data"
export ZSHRC_CONFIG_DIR="$DOTFILES_DIR/zshrc.d"

# Ensure DOTFILES_DIR/bin is in PATH
if [[ ":$PATH:" != *":$DOTFILES_DIR/bin:"* ]]; then
  export PATH="$PATH:$DOTFILES_DIR/bin"
  echo "Added \033[1;36m$DOTFILES_DIR/bin\033[m to \033[1;32m\$PATH\033[m"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Source non-lazy configurations
source "$ZSHRC_CONFIG_DIR/nonlazy.zsh"
source "$ZSHRC_CONFIG_DIR/pluginrc/sheldon.zsh"

# Source tmux config if not in SSH session or VSCode
if [[ "$TERM_PROGRAM" != "vscode" && -z "$SSH_CONNECTION" ]]; then
  source "$ZSHRC_CONFIG_DIR/pluginrc/tmux.zsh"
fi
