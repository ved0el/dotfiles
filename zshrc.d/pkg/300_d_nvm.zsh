#!/usr/bin/env zsh

PKG_NAME="nvm"
PKG_DESC="Node Version Manager"
PKG_CMD="nvm"

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
    # Check if NVM is installed by checking for the directory and script
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    if [[ ! -d "$nvm_dir" ]] || [[ ! -f "$nvm_dir/nvm.sh" ]]; then
        _dotfiles_log_error "NVM not found at $nvm_dir"
        return 1
    fi

    # NVM is lazy loaded via nvm_lazy.zsh
    # This provides lazy loading for node, npm, npx, yarn commands
    if [[ -r "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh" ]]; then
        source "$DOTFILES_ROOT/zshrc.d/lib/nvm_lazy.zsh" || {
            _dotfiles_log_error "Failed to load nvm_lazy.zsh"
            return 1
        }
        _dotfiles_log_debug "NVM lazy loading configured"
        return 0
    else
        _dotfiles_log_error "nvm_lazy.zsh not found"
        return 1
    fi
}

# Custom check function for NVM (it's a function, not a command)
_nvm_is_installed() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -d "$nvm_dir" ]] && [[ -f "$nvm_dir/nvm.sh" ]]
}

# Override the package check for NVM since it's a function, not a command
if _nvm_is_installed; then
    _dotfiles_log_debug "NVM is already installed ✓"
    _dotfiles_log_debug "Initializing NVM..."
    typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Failed to initialize NVM" && return 1; }
    _dotfiles_log_success "NVM initialized successfully"
else
    # Not installed - only attempt installation if verbose mode is on
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo
        _dotfiles_log_warning "NVM not found - $PKG_DESC"
        _dotfiles_log_info "Attempting to install NVM..."
        
        # Pre-install
        if typeset -f pkg_pre_install >/dev/null; then
            _dotfiles_log_debug "Running pre-install for NVM..."
            pkg_pre_install || { _dotfiles_log_error "Pre-install failed for NVM" && return 1; }
        fi
        
        # Install
        if typeset -f pkg_install >/dev/null; then
            _dotfiles_log_debug "Installing NVM..."
            pkg_install || { _dotfiles_log_error "Installation failed for NVM" && return 1; }
        else
            _dotfiles_install_package "$PKG_NAME" "$PKG_DESC" || { _dotfiles_log_error "Installation failed for NVM" && return 1; }
        fi
        
        # Verify installation
        if ! _nvm_is_installed; then
            _dotfiles_log_error "NVM installation completed but not found"
            return 1
        fi
        
        # Post-install
        if typeset -f pkg_post_install >/dev/null; then
            _dotfiles_log_debug "Running post-install for NVM..."
            pkg_post_install || _dotfiles_log_warning "Post-install failed for NVM"
        fi
        
        # Initialize
        _dotfiles_log_debug "Initializing NVM..."
        typeset -f pkg_init >/dev/null && pkg_init || { _dotfiles_log_error "Failed to initialize NVM" && return 1; }
        
        _dotfiles_log_success "NVM installed and initialized successfully ✓"
        echo
    else
        _dotfiles_log_debug "NVM not installed, skipping..."
    fi
fi
