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
    # Pin version explicitly — check https://github.com/nvm-sh/nvm/releases for latest.
    # Update nvm_version and installer_sha256 together when bumping.
    local nvm_version="v0.40.1"
    local installer_sha256="abdb525ee9f5b48b34d8ed9fc67c6013fb0f659712e401ecd88ab989b3af8f53"
    local install_url="https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh"
    _dotfiles_safe_run_installer "$install_url" "$installer_sha256"
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

    # Guard: don't re-register wrappers if already loaded (e.g. source ~/.zshrc)
    [[ "${_DOTFILES_NVM_LOADED:-}" == "1" ]] && return 0

    _lazy_load_nvm() {
        # Idempotency guard: nvm.sh already sourced (flag set below)
        [[ "${_DOTFILES_NVM_LOADED:-}" == "1" ]] && return 0

        [[ -f "$NVM_DIR/nvm.sh" ]] || return 1
        source "$NVM_DIR/nvm.sh"
        [[ -f "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion" 2>/dev/null

        typeset -f nvm >/dev/null 2>&1 || return 1
        export _DOTFILES_NVM_LOADED="1"

        # Prompt user to install Node if none present — don't auto-install silently
        if [[ -z "$(nvm list 2>/dev/null | grep -E 'v[0-9]+')" ]]; then
            echo "[dotfiles] No Node version installed. Run: nvm install --lts" >&2
            return 1
        else
            nvm use default &>/dev/null || \
            nvm use --lts  &>/dev/null || \
            nvm use node   &>/dev/null || {
                _dotfiles_log_error "nvm: no usable Node version found — run: nvm install --lts"
                return 1
            }
        fi
    }

    create_lazy_wrapper "nvm" "_lazy_load_nvm" "node" "npm" "npx"

    # yarn/pnpm: only wrap if not already available globally (outside nvm)
    # Wrapping a global install would intercept it and break it silently
    command -v yarn &>/dev/null || create_lazy_wrapper "yarn" "_lazy_load_nvm"
    command -v pnpm &>/dev/null || create_lazy_wrapper "pnpm" "_lazy_load_nvm"
}

init_package_template "$PKG_NAME"
