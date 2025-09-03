# Dotfiles Configuration - Fast, modular, and clean
# Core configuration loaded from zshrc.d/core modules

# Load core modules in order
for core_file in "$DOTFILES_ROOT"/zshrc.d/core/*.zsh(N); do
  [[ -f "$core_file" ]] && source "$core_file"
done

# Load plugins (skip tmux in VSCode/SSH)
for plugin_file in "$DOTFILES_ROOT"/zshrc.d/plugins/*.zsh(N); do
  if [[ "${plugin_file:t}" == "tmux.zsh" ]]; then
    [[ "$TERM_PROGRAM" != "vscode" && -z "$SSH_CONNECTION" && -n "$(command -v tmux 2>/dev/null)" ]] && source "$plugin_file"
  else
    [[ -f "$plugin_file" ]] && source "$plugin_file"
  fi
done