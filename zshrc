# =============================================================================
# Dotfiles Configuration
# =============================================================================
# This file is automatically managed by the dotfiles installer
# Core configuration is loaded from zshrc.d/core modules

# =============================================================================
# Core System (modular, fast)
# =============================================================================
# Load all core modules in lexicographic order (supports numeric prefixes)
if [[ -d "$DOTFILES_ROOT/zshrc.d/core" ]]; then
  for core_file in "$DOTFILES_ROOT"/zshrc.d/core/*.zsh(N); do
    source "$core_file"
  done
fi

# =============================================================================
# Plugins
# =============================================================================
# Load plugins via loop. Special-case tmux to avoid VSCode/SSH.
if [[ -d "$DOTFILES_ROOT/zshrc.d/plugins" ]]; then
  for plugin_file in "$DOTFILES_ROOT"/zshrc.d/plugins/*.zsh(N); do
    case "${plugin_file:t}" in
      tmux.zsh)
        if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ -z "$SSH_CONNECTION" ]] && command -v tmux >/dev/null 2>&1; then
          source "$plugin_file"
        fi
        ;;
      *)
        source "$plugin_file"
        ;;
    esac
  done
fi




