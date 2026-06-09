#!/usr/bin/env zsh
# environment — keep PATH set before sheldon/mise (they live in ~/.local/bin).
export EDITOR="${EDITOR:-micro}"
# micro: force 24-bit truecolor so the catppuccin-mocha colorscheme renders with
# its true palette instead of the 256-color approximation.
export MICRO_TRUECOLOR=1
# XDG_CONFIG_HOME explicit on every platform (Windows sets it in the bootstrap +
# PowerShell profile) so configs live under ~/.config identically everywhere — and
# mise/zoxide/etc. read the same tree instead of an OS-specific default.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# Actively UNSET MISE_GLOBAL_CONFIG_FILE / MISE_CONFIG_DIR (never set them). mise's default
# global config is already $XDG_CONFIG_HOME/mise/config.toml (chezmoi-ignored, so `mise use -g`
# pins stay untracked there). Setting MISE_GLOBAL_CONFIG_FILE is redundant AND makes mise stop
# auto-discovering the global config DIRECTORY (the conf.d/*.toml tool manifests) when CWD is
# outside $HOME — `mise ls` then reports no tools. Unset (not just skip) so a shell inheriting
# a stale value from an older session self-heals.
unset MISE_GLOBAL_CONFIG_FILE MISE_CONFIG_DIR
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"
