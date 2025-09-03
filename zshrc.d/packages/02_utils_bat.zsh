#!/usr/bin/env zsh

# Bat - Cat clone with syntax highlighting
PACKAGE_NAME="bat"

# Post-installation setup
post_install() {
  # Create symlink for batcat (Ubuntu/Debian) to bat
  if [[ -f /usr/bin/batcat && ! -f /usr/bin/bat ]]; then
    sudo ln -sf /usr/bin/batcat /usr/bin/bat
  fi
}

# Initialization
init() {
  if is_package_installed "$PACKAGE_NAME"; then
    alias cat="bat"
  fi
}

# Install if not present
if ! is_package_installed "$PACKAGE_NAME"; then
  install_package "$PACKAGE_NAME" "Cat clone with syntax highlighting"
  post_install
else
  init
fi
