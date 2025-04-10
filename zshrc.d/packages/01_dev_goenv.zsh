#!/usr/bin/env zsh

# =============================================================================
# Goenv Installation Script
# =============================================================================

# Package Information
PACKAGE_NAME="goenv"
PACKAGE_DESC="Go Version Management"
PACKAGE_DEPS=""

# Installation Methods
typeset -A install_methods
install_methods=(
  [brew]="brew install goenv"
  [custom]="git clone https://github.com/go-nv/goenv.git ~/.goenv"
)

# Pre-installation function
pre_install() {
  export GOENV_ROOT="$HOME/.goenv"
}

# Post-installation function
post_install() {
  export PATH="$PATH:$GOENV_ROOT/bin:$GOROOT/bin:$GOPATH/bin"

  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable"
  else
    # Initialize goenv
    eval "$(goenv init - zsh)"

    local latest_version=$(goenv install -l | grep -v '[a-zA-Z]' | tail -1 | tr -d '[[:space:]]')
    goenv install $latest_version
    goenv global $latest_version
    goenv rehash
  fi
}

init() {
  export GOENV_ROOT="$HOME/.goenv"
  export PATH="$PATH:$GOENV_ROOT/bin:$GOROOT/bin:$GOPATH/bin"
  eval "$(goenv init - zsh)"
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
