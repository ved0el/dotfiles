#!/usr/bin/env zsh

# =============================================================================
# curlie Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="curlie"
PACKAGE_DESC="The power of curl, the ease of use of httpie"
PACKAGE_DEPS="go"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install curlie"
  [custom]="go install github.com/rs/curlie@latest"
)

# Pre-installation function
pre_install() {
  return
}

# Post-installation function
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable"
  else
    alias curl ="curlie"
  fi
}

# Initialization function
init(){
  return
}

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
