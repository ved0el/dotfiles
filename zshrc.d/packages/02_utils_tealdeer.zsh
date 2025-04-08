#!/usr/bin/env zsh

# =============================================================================
# tealdeer Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="tldr"
PACKAGE_DESC="A fast tldr client in Rust"

# Installation methods
typeset -A install_methods
install_methods=(
    [brew]="brew install tealdeer"
    [apt]="sudo apt install -y tealdeer"
    [pacman]="sudo pacman -S --noconfirm tealdeer"
    [custom]="cargo install tealdeer"
)

# Pre-installation function
pre_install() {
    # Create config directory
    mkdir -p "${XDG_CONFIG_HOME}/tealdeer"
}

# Post-installation function
post_install() {
    if ! is_package_installed "$PACKAGE_NAME"; then
        log_success "$PACKAGE_NAME is already installed"
    fi

    # Update tldr pages cache
    tldr --update
}

# Initialization function
init() {
    # Set alias
    alias tldr='tldr --color always'
}

# Main installation flow
if ! is_package_installed "$PACKAGE_NAME"; then
    pre_install
    install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
    post_install
else
    init
fi
