#!/usr/bin/env zsh

PKG_NAME="zoxide"
PKG_DESC="A smarter cd command"

pkg_init() {
    # Initialize zoxide and capture any errors
    local zoxide_init_output
    zoxide_init_output=$(zoxide init zsh 2>&1)

    if [[ $? -eq 0 && -n "$zoxide_init_output" ]]; then
        # Initialization successful, evaluate the output
        eval "$zoxide_init_output" || {
            _dotfiles_log_error "Failed to evaluate zoxide initialization"
            return 1
        }

        # Verify that the z function was created
        if ! typeset -f __zoxide_z >/dev/null; then
            _dotfiles_log_error "zoxide initialization incomplete: __zoxide_z function not found"
            return 1
        fi

        # Verify that the z command wrapper exists
        if ! typeset -f z >/dev/null; then
            _dotfiles_log_error "zoxide initialization incomplete: z function not found"
            return 1
        fi

        # Create a safe wrapper for cd that falls back to builtin cd if z fails
        _safe_zoxide_cd() {
            if typeset -f z >/dev/null; then
                z "$@"
            else
                _dotfiles_log_error "zoxide not properly initialized, using builtin cd"
                builtin cd "$@"
            fi
        }

        # Only create aliases if initialization succeeded
        alias cd="_safe_zoxide_cd"
        alias cdi="zi"

        # Set FZF options for zoxide interactive mode
        export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 --group-directories-first --header --no-user --no-time --no-filesize --no-permissions {2..}' --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."

        _dotfiles_log_debug "zoxide initialized successfully with cd alias"
        return 0
    else
        _dotfiles_log_error "Failed to initialize zoxide"
        return 1
    fi
}

init_package_template "$PKG_NAME"
