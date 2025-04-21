# =============================================================================
# Environment Setup
# =============================================================================

export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"
export ZSHRC_CONFIG_DIR="$DOTFILES_ROOT/zshrc.d"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# =============================================================================
# Core
# =============================================================================
for file in "$ZSHRC_CONFIG_DIR"/core/*.zsh(N); do
    if [[ -r "$file" ]]; then
      source "$file"
    fi
done

# =============================================================================
# Plugins
# =============================================================================

# Load Sheldon plugin manager
source "$ZSHRC_CONFIG_DIR/plugins/sheldon.zsh"

# Source tmux config if not in SSH session or VSCode
if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ -z "$SSH_CONNECTION" ]] && command -v tmux >/dev/null 2>&1; then
  source "$ZSHRC_CONFIG_DIR/plugins/tmux.zsh"
fi

# =============================================================================
# Packages
# =============================================================================

source "$ZSHRC_CONFIG_DIR/functions/package_installer.zsh"


# Load Powerlevel10k theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
