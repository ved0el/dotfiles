#!/usr/bin/env zsh

# =============================================================================
# tmux Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="tmux"
PACKAGE_DESC="A terminal multiplexer"
PACKAGE_DEPS=""

# Installation methods
typeset -A install_methods
install_methods=(
    [brew]="brew install tmux"
    [apt]="sudo apt install -y tmux"
    [pacman]="sudo pacman -S --noconfirm tmux"
    [custom]="git clone https://github.com/tmux/tmux.git ~/tmux && cd ~/tmux && sh autogen.sh && ./configure && make && sudo make install"
)

pre_install() {
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
}

# Post-installation commands
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable"
  else
    # Install Tmux Plugin Manager (tpm)
    if [[ ! -d $TMUX_PLUGIN_MANAGER_PATH/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGIN_MANAGER_PATH/tpm
    fi

    [[ -f $HOME/.tmux.conf ]] && $TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins
  fi
}

init() {
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
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
