#!/usr/bin/env zsh

# NVM Lazy Loading
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

lazy_load_nvm() {
    [[ -f "${NVM_DIR}/nvm.sh" ]] && source "${NVM_DIR}/nvm.sh"
    [[ -f "${NVM_DIR}/bash_completion" ]] && source "${NVM_DIR}/bash_completion"
}

# Only create lazy wrappers if nvm is installed
[[ -d "${NVM_DIR}" ]] && [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" ]] && {
    source "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh"
    create_lazy_wrapper "nvm" "lazy_load_nvm" "node" "npm" "npx" "yarn"
}
