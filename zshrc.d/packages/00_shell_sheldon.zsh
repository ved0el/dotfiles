#!/usr/bin/env zsh

# Sheldon Plugin Manager
PACKAGE_NAME="sheldon"

# Pre-installation
pre_install() {
  mkdir -p "$XDG_CONFIG_HOME/sheldon"
}

# Post-installation
post_install() {
  if is_package_installed "$PACKAGE_NAME"; then
    sheldon init --shell zsh
    sheldon lock --update
  fi
}

# Initialization
init() {
  if is_package_installed "$PACKAGE_NAME" && [[ -f "$XDG_CONFIG_HOME/sheldon/plugins.toml" ]]; then
    eval "$(sheldon source)"
  fi
}

# Install if not present
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package "$PACKAGE_NAME" "Shell plugin manager"
  post_install
else
  init
fi
