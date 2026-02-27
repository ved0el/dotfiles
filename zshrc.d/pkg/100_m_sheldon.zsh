#!/usr/bin/env zsh

PKG_NAME="sheldon"
PKG_DESC="A fast and configurable shell plugin manager"

pkg_install() {
    # Fallback: curl installer for Linux when package manager fails
    if [[ "$(uname -s)" == "Linux" ]] && command -v curl &>/dev/null; then
        _dotfiles_log_debug "Trying curl-based installer for $PKG_NAME..."
        curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \
            sudo bash -s -- --repo rossmacarthur/sheldon --to "/usr/local/bin" &>/dev/null
    else
        _dotfiles_install_package "$PKG_NAME" "$PKG_DESC" || return 1
    fi
}

pkg_post_install() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon"
    local config_file="${config_dir}/plugins.toml"

    ensure_directory "$config_dir"
    copy_if_missing "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "$config_file"
    sheldon lock --update &>/dev/null || _dotfiles_log_warning "Failed to update $PKG_NAME plugins."
}

pkg_init() {
    eval "$(sheldon source)"

    # Initialize completions AFTER sheldon so zsh-completions is fully in fpath
    autoload -Uz compinit
    if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
    else
        compinit -C
    fi
}

init_package_template "$PKG_NAME"
