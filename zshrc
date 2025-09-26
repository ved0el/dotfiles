# =============================================================================
# Dotfiles ZSH Configuration
# Modern, cross-platform shell configuration
# =============================================================================

# Environment Setup
export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"
export DOTFILES_DIR="$HOME/.dotfiles"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export ZSHRC_CONFIG_DIR="$DOTFILES_DIR/zshrc.d"

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Core Configuration Loading
# =============================================================================

# Load core configurations
for config_file in "$ZSHRC_CONFIG_DIR"/core/*.zsh(N); do
    [[ -r "$config_file" ]] && source "$config_file"
done

# Load functions
for function_file in "$ZSHRC_CONFIG_DIR"/functions/*.zsh(N); do
    [[ -r "$function_file" ]] && source "$function_file"
done

# =============================================================================
# Plugin Management
# =============================================================================

# Initialize Sheldon plugin manager
if command -v sheldon >/dev/null 2>&1; then
    eval "$(sheldon source)"
else
    echo "Warning: Sheldon plugin manager not found. Run the installer to set it up."
fi

# =============================================================================
# Conditional Tool Loading
# =============================================================================

# Load tmux configuration if not in SSH or IDE environment
if [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && "${TERM_PROGRAM:-}" != "vscode" && -z "${VSCODE_PID:-}" && -z "${CURSOR_PID:-}" ]]; then
    if [[ -f "$ZSHRC_CONFIG_DIR/plugins/tmux.zsh" ]]; then
        source "$ZSHRC_CONFIG_DIR/plugins/tmux.zsh"
    fi
fi

# =============================================================================
# Development Environment Setup
# =============================================================================

# Node Version Manager (NVM)
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# Python Environment Manager (pyenv)
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Go Environment Manager (g)
if [[ -s "$HOME/.g/env" ]]; then
    source "$HOME/.g/env"
fi

# =============================================================================
# Shell Enhancements
# =============================================================================

# Initialize zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Initialize fzf
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
fi

# Load Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
