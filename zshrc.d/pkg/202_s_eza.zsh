#!/usr/bin/env zsh

PKG_NAME="eza"
PKG_DESC="A modern replacement for ls"

pkg_init() {
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias lt="eza --tree"
  alias lta="eza --tree -a"
}

init_package_template "$PKG_NAME"
