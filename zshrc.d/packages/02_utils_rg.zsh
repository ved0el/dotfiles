#!/usr/bin/env zsh

# =============================================================================
# ripgrep Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="rg"
PACKAGE_DESC="A line-oriented search tool that recursively searches the current directory"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install ripgrep"
  [apt]="sudo apt install -y ripgrep"
  [pacman]="sudo pacman -S --noconfirm ripgrep"
  [custom]="cargo install ripgrep"
)

# Pre-installation commands
pre_install() {
  return
}

# Post-installation commands
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_success "$PACKAGE_NAME is already installed"
  fi
}

# Initialization function
init() {
  return
}

# Main installation flow
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  post_install
else
  init
fi
