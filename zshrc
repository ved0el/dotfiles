# Dotfiles Configuration - Fast, modular, and clean
# Core configuration loaded from zshrc.d/core modules

# Load core modules in order
for core_file in "$DOTFILES_ROOT"/zshrc.d/core/*.zsh(N); do
  [[ -f "$core_file" ]] && source "$core_file"
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
