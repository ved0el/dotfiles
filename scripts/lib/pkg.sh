#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then return; fi
  log_info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" | cat
  if [[ "$DETECTED_OS" == "macos" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

apt_install() {
  if [ "$(id -u)" -eq 0 ]; then
    apt-get update -y | cat
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" | cat
  else
    sudo apt-get update -y | cat
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" | cat
  fi
}

brew_install() {
  brew update | cat
  brew install "$@" | cat
}

install_pkg() {
  case "$DETECTED_OS_FAMILY" in
    macos)
      ensure_homebrew
      brew_install "$@"
      ;;
    debian)
      apt_install "$@"
      ;;
    *)
      log_warn "No package recipe for $DETECTED_OS_FAMILY; skipping $*"
      ;;
  esac
}

maybe_chsh_to_zsh() {
  if command -v zsh >/dev/null 2>&1; then
    if [ "$SHELL" != "$(command -v zsh)" ]; then
      if command -v chsh >/dev/null 2>&1; then
        log_info "Attempting to set default shell to zsh"
        chsh -s "$(command -v zsh)" || log_warn "chsh failed; set default shell manually"
      fi
    fi
  fi
}

