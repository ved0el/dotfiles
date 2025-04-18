#!/usr/bin/env zsh

# =============================================================================
# bat Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="bat"
PACKAGE_DESC="A cat clone with syntax highlighting and Git integration"
PACKAGE_DEPS=""

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install bat"
  [apt]="sudo apt install -y bat"
  [yum]="sudo yum install -y bat"
  [pacman]="sudo pacman -S --noconfirm bat"
  [custom]="cargo install bat"
)

pre_install(){}

post_install() {
  # Create symlink for batcat (Ubuntu/Debian) to bat
  if [[ -f /usr/bin/batcat ]]; then
    log_info "Creating symlink from batcat to bat"
    sudo ln -sf /usr/bin/batcat /usr/bin/bat
  fi

  if ! is_package_installed "$PACKAGE_NAME"; then
    log_success "$PACKAGE_NAME is not executable"
  else
    return
  fi
}

init(){
  alias cat="bat"
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
