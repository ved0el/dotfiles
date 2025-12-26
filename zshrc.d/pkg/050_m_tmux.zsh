#!/usr/bin/env zsh

PKG_NAME="tmux"
PKG_DESC="Terminal multiplexer for managing multiple shell sessions"

pkg_post_install() {
    local tmux_conf="${DOTFILES_ROOT}/tmux.conf"
    local target="$HOME/.tmux.conf"

    # Create symlink for tmux.conf
    create_symlink "$tmux_conf" "$target"

    # Setup TPM (tmux plugin manager)
    source "${DOTFILES_ROOT}/zshrc.d/lib/tmux_loader.zsh" 2>/dev/null
}

pkg_init() {
    # Tmux initialization is handled by tmux_loader.zsh if needed
    # Just verify tmux is available
    return 0
}

init_package_template "$PKG_NAME"
