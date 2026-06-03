#!/usr/bin/env zsh
# environment — keep PATH set before sheldon/mise (they live in ~/.local/bin).
export EDITOR="${EDITOR:-vim}"
# XDG_CONFIG_HOME explicit on every platform (Windows sets it in the bootstrap +
# PowerShell profile) so configs live under ~/.config identically everywhere — and
# mise/zoxide/etc. read the same tree instead of an OS-specific default.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# Machine-local mise config: `mise use -g` writes here, NOT into the chezmoi-managed
# conf.d/*.toml. This file is chezmoi-ignored, so per-machine tool pins stay untracked.
export MISE_GLOBAL_CONFIG_FILE="${MISE_GLOBAL_CONFIG_FILE:-$XDG_CONFIG_HOME/mise/config.toml}"
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"
