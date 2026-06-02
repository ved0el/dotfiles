#!/usr/bin/env zsh
# environment — keep PATH set before sheldon/mise (they live in ~/.local/bin).
export EDITOR="${EDITOR:-vim}"
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"
