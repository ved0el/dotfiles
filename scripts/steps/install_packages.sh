#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# shellcheck disable=SC1091
source "$LIB_DIR/utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/os.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/pkg.sh"

detect_os
detect_environment

INSTALL_TMUX=1
if [ "$IS_SSH" -eq 1 ] || [ "$IS_IDE" -eq 1 ]; then
  INSTALL_TMUX=0
fi

log_info "Installing base packages (git, zsh)..."
case "$DETECTED_OS_FAMILY" in
  macos)
    install_pkg git zsh
    ;;
  debian)
    # ensure build tools for possible cargo sheldon build
    install_pkg git zsh build-essential pkg-config libssl-dev curl ca-certificates
    ;;
  *)
    log_warn "Unsupported package family: $DETECTED_OS_FAMILY"
    ;;
esac

if ! command -v sheldon >/dev/null 2>&1; then
  log_info "Installing sheldon..."
  if [ "$DETECTED_OS_FAMILY" = "macos" ]; then
    install_pkg sheldon
  else
    if command -v brew >/dev/null 2>&1; then
      brew_install sheldon
    else
      if ! command -v cargo >/dev/null 2>&1; then
        log_info "Installing Rust toolchain (for sheldon via cargo)..."
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path | cat
        export PATH="$HOME/.cargo/bin:$PATH"
      else
        export PATH="$HOME/.cargo/bin:$PATH"
      fi
      cargo install sheldon | cat || log_warn "Cargo install sheldon failed"
    fi
  fi
else
  log_info "sheldon already installed"
fi

if [ "$INSTALL_TMUX" -eq 1 ]; then
  log_info "Installing tmux..."
  install_pkg tmux || log_warn "tmux install skipped/failed"
else
  log_info "Skipping tmux install (SSH/IDE environment detected)"
fi

maybe_chsh_to_zsh

log_success "Package installation step complete"

