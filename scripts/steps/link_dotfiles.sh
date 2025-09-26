#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# shellcheck disable=SC1091
source "$LIB_DIR/utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/os.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/link.sh"

detect_os
detect_environment

DOTS_DIR="$REPO_ROOT/dotfiles"

log_info "Linking dotfiles..."

# Git
link_file "$DOTS_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Zsh
link_file "$DOTS_DIR/zsh/.zshrc" "$HOME/.zshrc"

# Sheldon
mkdir -p "$HOME/.config/sheldon"
link_file "$DOTS_DIR/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

# Tmux (only if not SSH/IDE)
if [ "$IS_SSH" -eq 0 ] && [ "$IS_IDE" -eq 0 ]; then
  link_file "$DOTS_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
else
  log_info "Skipping tmux config link (SSH/IDE environment detected)"
fi

log_success "Dotfiles linked"

