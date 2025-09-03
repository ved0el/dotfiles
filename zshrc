# Fast Zsh Configuration - Optimized for Speed

# Essential environment
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$DOTFILES_DIR/config"

# Load core modules (fast path)
for file in "$DOTFILES_DIR/zshrc.d/core"/*.zsh(N); do
  [[ -r "$file" ]] && source "$file"
done

# Load packages based on profile
source "$DOTFILES_DIR/zshrc.d/functions/package_installer.zsh"
load_packages

# Load plugins
source "$DOTFILES_DIR/zshrc.d/plugins/sheldon.zsh"
[[ "$TERM_PROGRAM" != "vscode" && -z "$SSH_CONNECTION" && -n "$(command -v tmux)" ]] && \
  source "$DOTFILES_DIR/zshrc.d/plugins/tmux.zsh"
