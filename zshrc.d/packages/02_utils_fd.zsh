#!/usr/bin/env zsh

# =============================================================================
# fd Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="fd"
PACKAGE_DESC="A simple, fast and user-friendly alternative to find"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install fd"
  [apt]="sudo apt install -y fd-find"
  [pacman]="sudo pacman -S --noconfirm fd"
  [custom]="cargo install fd-find"
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
  # Create symlink for fd-find (Ubuntu/Debian) to fd
  if [[ -f /usr/bin/fdfind ]]; then
    sudo ln -sf /usr/bin/fdfind /usr/bin/fd
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
fi
