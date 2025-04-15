#!/usr/bin/env zsh

# =============================================================================
# sheldon Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="sheldon"
PACKAGE_DESC="A fast and configurable shell plugin manager"
PACKAGE_DEPS=""

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install sheldon"
  [cargo]="cargo install sheldon"
  [custom]="curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to $DOTFILES_ROOT/bin"
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
    log_error "$PACKAGE_NAME is not executable"
  else
    sheldon lock --update
  fi
}

# Initialize
init(){
  return
}

# Main installation flow
# Main installation flow
if is_dependency_installed "$PACKAGE_DEPS"; then
  if ! is_package_installed "$PACKAGE_NAME"; then
      pre_install
      install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
      post_install
  else
    init
  fi
else
  log_error "Failed to install $PACKAGE_NAME"
fi
