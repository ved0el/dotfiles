#!/usr/bin/env zsh

# =============================================================================
# sheldon Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="sheldon"
PACKAGE_DESC="A fast and configurable shell plugin manager"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install sheldon"
  [cargo]="cargo install sheldon"
  [custom]="curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to /usr/local/bin"
)

# Pre-installation commands
pre_install() {
  # Create config directory if it doesn't exist
  if [[ ! -d $XDG_CONFIG_HOME/sheldon ]]; then
    mkdir -p $XDG_CONFIG_HOME/sheldon
  fi
}

# Post-installation commands
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_success "$PACKAGE_NAME is already installed"
  fi
  sheldon init
}

# Initialize
init() {

}

# Main installation flow
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  post_install
else
  init
fi
