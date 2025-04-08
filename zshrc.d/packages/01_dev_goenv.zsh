#!/usr/bin/env zsh

# =============================================================================
# Goenv Installation Script
# =============================================================================

# Package Information
PACKAGE_NAME="goenv"
PACKAGE_DESC="Go Version Management"

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
    log_success "$PACKAGE_NAME is already installed"
  fi

  # Initialize goenv
  eval "$(goenv init -)"

  local latest_version=$(goenv install -l | grep -v '[a-zA-Z]' | tail -1 | tr -d '[[:space:]]')
  goenv install $latest_version
  goenv global $latest_version
  goenv rehash
}

init() {
  export GOENV_ROOT="$HOME/.goenv"
  export PATH="$PATH:$GOENV_ROOT/bin:$GOROOT/bin:$GOPATH/bin"

  # Initialize goenv if installed
  if command -v goenv >/dev/null; then
        eval "$(goenv init -)"
  fi
}

if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  post_install
else
  init
fi
