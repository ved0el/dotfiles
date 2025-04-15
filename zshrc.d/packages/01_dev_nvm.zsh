#!/usr/bin/env zsh

# =============================================================================
# nvm Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="nvm"
PACKAGE_DESC="Node Version Manager"
PACKAGE_DEPS=""

# Installation methods
typeset -A install_methods
install_methods=(
  [custom]="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash"
)

# Pre-installation commands
pre_install() {
  export NVM_DIR="$HOME/.nvm"
  # Create nvm directory if it doesn't exist
  if [[ ! -d "$NVM_DIR" ]]; then
    mkdir -p "$NVM_DIR"
  fi
}

post_install(){
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable"
  else
    # Load nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

    # Install Node.js LTS version
    nvm install --lts
    nvm use --lts
  fi
}

init(){
  return
}

# Main installation flow
if [[ ! -d "$NVM_DIR" ]]; then
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
fi
