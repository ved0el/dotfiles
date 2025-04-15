# =============================================================================
# Environment Configuration
# =============================================================================
# Ensure DOTFILES_ROOT/bin is in PATH
if [[ ":$PATH:" != *":$DOTFILES_ROOT/bin:"* ]]; then
  export PATH="$PATH:$DOTFILES_ROOT/bin"
fi

# Add local bin to PATH
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

# =============================================================================
# NVM Lazy Loading
# =============================================================================

export NVM_LAZY_LOAD="true"
