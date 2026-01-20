#!/usr/bin/env zsh

PKG_NAME="zoxide"
PKG_DESC="A smarter cd command"

pkg_init() {
    # Check if zoxide is available
    if ! command -v zoxide &>/dev/null; then
        _dotfiles_log_error "zoxide command not found"
        return 1
    fi

    # Initialize zoxide - this creates the z and zi functions/aliases
    eval "$(zoxide init zsh)" || {
        _dotfiles_log_error "Failed to initialize zoxide"
        return 1
    }

    # Verify that zoxide was initialized correctly by checking for the z function
    if ! typeset -f __zoxide_z &>/dev/null; then
        _dotfiles_log_error "zoxide initialization incomplete: __zoxide_z function not found"
        return 1
    fi

    # Set FZF options for zoxide interactive mode (if eza is available)
    if command -v eza &>/dev/null; then
        export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 --group-directories-first --header --no-user --no-time --no-filesize --no-permissions {2..}' --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."
    fi

    _dotfiles_log_debug "zoxide initialized successfully"
    return 0
}

init_package_template "$PKG_NAME"
