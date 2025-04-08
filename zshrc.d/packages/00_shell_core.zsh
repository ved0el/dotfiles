#!/usr/bin/env zsh

# =============================================================================
# Core Utilities Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="core-utils"
PACKAGE_DESC="Essential command line utilities (curl, wget, git)"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install curl wget git"
  [apt]="sudo apt update && sudo apt install -y curl wget git"
  [dnf]="sudo dnf install -y curl wget git"
  [yum]="sudo yum install -y curl wget git"
  [pacman]="sudo pacman -Sy curl wget git"
)

# Check if all core utilities are installed
check_core_utils() {
  local missing=()
  for util in curl wget git; do
    if ! command -v $util &>/dev/null; then
      missing+=($util)
    fi
  done

  if [[ ${#missing} -eq 0 ]]; then
    return 0
  else
    log_info "Missing utilities: ${missing[*]}"
    return 1
  fi
}

# Main installation flow
if ! check_core_utils; then
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  log_success "All core utilities are already installed"
fi
