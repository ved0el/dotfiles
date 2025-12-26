#!/usr/bin/env zsh

PKG_NAME="nvm"
PKG_DESC="Node Version Manager"
PKG_CMD="nvm"

# Override the default package check - nvm is a function, not a command
is_package_installed() {
    [[ -d "${NVM_DIR:-$HOME/.nvm}" ]] && [[ -f "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]
}

pkg_install() {
    # NVM requires custom installation script
    local install_dir="${NVM_DIR:-$HOME/.nvm}"

    _dotfiles_log_info "Installing NVM (Node Version Manager)..."

    # Create NVM directory if it doesn't exist
    ensure_directory "$install_dir"

    # Install NVM using official installer with latest version
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
        _dotfiles_log_success "NVM installed successfully"
        return 0
    else
        _dotfiles_log_error "Failed to install NVM"
        return 1
    fi
}

pkg_post_install() {
    # Ensure NVM_DIR is set in current session
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    # Verify installation
    if [[ -d "$NVM_DIR" ]] && [[ -f "$NVM_DIR/nvm.sh" ]]; then
        _dotfiles_log_success "NVM installation verified at: $NVM_DIR"
        return 0
    else
        _dotfiles_log_error "NVM installation verification failed"
        return 1
    fi
}

pkg_init() {
    # NVM is lazy loaded via nvm_lazy.zsh
    # This provides lazy loading for node, npm, npx, yarn commands
    if [[ -r "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh" ]]; then
        source "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh" || {
            _dotfiles_log_error "Failed to load nvm_lazy.zsh"
            return 1
        }
        _dotfiles_log_debug "NVM lazy loading configured"
    else
        _dotfiles_log_error "nvm_lazy.zsh not found"
        return 1
    fi
}

init_package_template "$PKG_NAME"
