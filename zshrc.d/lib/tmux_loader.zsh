#!/usr/bin/env zsh

# Install and setup tmux plugin manager (TPM)
_tmux_setup_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  local tpm_install_script="$tpm_dir/bindings/install_plugins"

  # Check if TPM exists, if not install it
  if [[ ! -d "$tpm_dir" ]]; then
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "Installing tmux plugin manager..."
    if command -v git &>/dev/null; then
      git clone https://github.com/tmux-plugins/tpm "$tpm_dir" &>/dev/null
      if [[ $? -eq 0 ]]; then
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ TPM installed successfully"
      else
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "⚠️ Failed to install TPM"
        return 1
      fi
    else
      [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "⚠️ git not found, cannot install TPM"
      return 1
    fi
  fi

  # Install all plugins if TPM is available
  if [[ -f "$tpm_install_script" ]]; then
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "Installing tmux plugins..."
    "$tpm_install_script" &>/dev/null
    [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ Tmux plugins installed"
  fi
}

# Setup TPM and plugins
_tmux_setup_tpm

# Auto-start tmux (skip in integrated terminals and SSH)
# Check if tmux command exists
if [[ -n "$(command -v tmux 2>/dev/null)" ]]; then
  # Check if not in SSH connection
  if [[ -z "$SSH_CONNECTION" ]]; then
    # Check if not in integrated terminals (vscode, cursor, etc.)
    local is_integrated_terminal=false
    case "$TERM_PROGRAM" in
      vscode|cursor|WezTerm|Hyper|iTerm.app|Apple_Terminal)
        is_integrated_terminal=true
        ;;
    esac

    # Also check for VSCODE_INJECTION which indicates VSCode terminal
    [[ -n "$VSCODE_INJECTION" ]] && is_integrated_terminal=true

    # Only start tmux if not in integrated terminal and not already in tmux session
    if [[ "$is_integrated_terminal" == false && -z "$TMUX" ]]; then
      # Attach to existing session or create a new one
      exec tmux new-session -A -s main
    fi
  fi
fi
