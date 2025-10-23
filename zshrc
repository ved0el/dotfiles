# Dotfiles Configuration - Fast, modular, and clean
# Core configuration loaded from zshrc.d/core modules

# Load core modules in order
for core_file in "$DOTFILES_ROOT"/zshrc.d/core/*.zsh(N); do
  [[ -f "$core_file" ]] && source "$core_file"
done

# NVM is now lazy loaded - no longer loaded at startup
