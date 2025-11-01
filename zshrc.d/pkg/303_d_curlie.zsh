#!/usr/bin/env zsh

PKG_NAME="curlie"
PKG_DESC="The power of curl, the ease of use of httpie"

pkg_init() {
  alias http="curlie"
}

init_package_template "$PKG_NAME"
