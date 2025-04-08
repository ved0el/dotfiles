#!/usr/bin/env zsh

# =============================================================================
# eza Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="eza"
PACKAGE_DESC="A modern replacement for ls"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install eza"
  [apt]="sudo apt install -y eza"
  [pacman]="sudo pacman -S --noconfirm eza"
  [custom]="cargo install eza"
)

# Pre-installation function
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
init(){}

# Main installation flow
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  post_install
else
  init
fi
