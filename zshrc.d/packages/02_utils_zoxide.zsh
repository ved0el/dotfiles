#!/usr/bin/env zsh

# =============================================================================
# zoxide Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="zoxide"
PACKAGE_DESC="A smarter cd command"
PACKAGE_DEPS=""

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install zoxide"
  [apt]="sudo apt install -y zoxide"
  [pacman]="sudo pacman -S --noconfirm zoxide"
  [custom]="curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo ajeetdsouza/zoxide --to $DOTFILES_DIR/bin"
)

# Pre-installation commands
pre_install() {
  export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 \
    --group-directories-first \
    --header --no-user --no-time --no-filesize --no-permissions {2..}' \
    --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."
}

# Post-installation commands
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable"
  else
    eval "$(zoxide init zsh)"
    alias cd="z"
  fi
}

# Initialization function
init() {
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
