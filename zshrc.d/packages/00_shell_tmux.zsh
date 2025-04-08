#!/usr/bin/env zsh

# =============================================================================
# tmux Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="tmux"
PACKAGE_DESC="A terminal multiplexer"

# Check if we're in an appropriate environment for tmux
should_install_tmux() {
    # Check if we're in SSH session
    [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] && return 1

    # Check for common IDE/embedded terminals
    [[ "$TERM_PROGRAM" == "vscode" ]] && return 1
    [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]] && return 1
    [[ -n "$CURSOR_TERMINAL" ]] && return 1

    # Check if we're in an interactive shell
    [[ ! -t 1 ]] && return 1

    return 0
}

# Installation methods
typeset -A install_methods
install_methods=(
    [brew]="brew install tmux"
    [apt]="sudo apt install -y tmux"
    [pacman]="sudo pacman -S --noconfirm tmux"
    [custom]="git clone https://github.com/tmux/tmux.git ~/tmux && cd ~/tmux && sh autogen.sh && ./configure && make && sudo make install"
)

pre_install() {
    export TMUX_PLUGIN_PATH="$HOME/.tmux/plugins"
}

# Post-installation commands
post_install() {
    # Install Tmux Plugin Manager (tpm)
    if [[ ! -d $TMUX_PLUGIN_PATH/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGIN_PATH/tpm
    fi

    [[ -f $HOME/.tmux.conf ]] && $TMUX_PLUGIN_PATH/tpm/bin/install_plugins
}

init() {
    export TMUX_PLUGIN_PATH="$HOME/.tmux/plugins"
}

# Main installation flow
if should_install_tmux; then
    if ! is_package_installed "$PACKAGE_NAME"; then
        pre_install
        install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
        post_install
    else
        init
    fi
fi
