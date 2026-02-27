#!/usr/bin/env zsh

PKG_NAME="nvm"
PKG_DESC="Node Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_nvm_is_installed"

_nvm_is_installed() {
    local dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -d "$dir" ]] && [[ -f "$dir/nvm.sh" ]]
}

pkg_install() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
}

pkg_post_install() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -d "$NVM_DIR" ]] && [[ -f "$NVM_DIR/nvm.sh" ]]; then
        _dotfiles_log_success "NVM verified at: $NVM_DIR"
    else
        _dotfiles_log_error "NVM installation verification failed"
        return 1
    fi
}

pkg_init() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    _lazy_load_nvm() {
        # Idempotency guard: skip if nvm is already a real function
        typeset -f nvm >/dev/null 2>&1 && return 0

        [[ -f "$NVM_DIR/nvm.sh" ]] || return 1
        source "$NVM_DIR/nvm.sh"
        [[ -f "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion" 2>/dev/null

        typeset -f nvm >/dev/null 2>&1 || return 1

        # Auto-install LTS if no Node version is installed
        if [[ -z "$(nvm list 2>/dev/null | grep -E 'v[0-9]+')" ]]; then
            nvm install --lts && nvm alias default 'lts/*' && nvm use --lts
        else
            nvm use default &>/dev/null || nvm use --lts &>/dev/null || nvm use node &>/dev/null
        fi
    }

    create_lazy_wrapper "nvm" "_lazy_load_nvm" "node" "npm" "npx"

    # yarn/pnpm: only wrap if not already available globally (outside nvm)
    # Wrapping a global install would intercept it and break it silently
    command -v yarn &>/dev/null || create_lazy_wrapper "yarn" "_lazy_load_nvm"
    command -v pnpm &>/dev/null || create_lazy_wrapper "pnpm" "_lazy_load_nvm"
}

init_package_template "$PKG_NAME"
