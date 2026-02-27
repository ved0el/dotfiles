#!/usr/bin/env zsh

PKG_NAME="sheldon"
PKG_DESC="A fast and configurable shell plugin manager"

pkg_install() {
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
    ensure_directory "$config_dir"
    copy_if_missing "${DOTFILES_ROOT}/config/sheldon/plugins.toml" "${config_dir}/plugins.toml"
    sheldon lock --update &>/dev/null || _dotfiles_log_warning "Failed to update $PKG_NAME plugins."
}

pkg_init() {
    eval "$(sheldon source)"

    # Initialize completions AFTER sheldon so zsh-completions is fully in fpath.
    # 30-completion.zsh sets zstyle only; compinit must run here.
    autoload -Uz compinit
    if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit        # full rebuild (at most once per day)
    else
        compinit -C     # use cached dump, skip security check
    fi
}

init_package_template "$PKG_NAME"
