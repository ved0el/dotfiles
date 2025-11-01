#!/usr/bin/env zsh

PKG_NAME="fd"
PKG_DESC="A simple, fast and user-friendly alternative to find"

pkg_init() {
  alias find="fd"
  export FD_OPTIONS="--follow --exclude .git --exclude node_modules"
}

init_package_template "$PKG_NAME"
