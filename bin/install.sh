#!/usr/bin/env bash

# =============================================================================
# Simple Dotfiles Installer
# =============================================================================

set -euo pipefail

# Configuration
readonly REPO_URL="https://github.com/ved0el/dotfiles.git"
readonly DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
readonly DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check dependencies
check_deps() {
  local missing=()
  for cmd in git curl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing dependencies: ${missing[*]}"
    exit 1
  fi
}

# Clone or update repository
setup_repo() {
  if [[ -d "$DOTFILES_ROOT/.git" ]]; then
    log_info "Updating existing repository..."
    (cd "$DOTFILES_ROOT" && git pull --quiet)
  else
    log_info "Cloning repository to $DOTFILES_ROOT..."
    git clone --quiet "$REPO_URL" "$DOTFILES_ROOT"
  fi
}

# Create symlinks
create_links() {
  log_info "Creating symlinks..."

  local count=0
  while IFS= read -r -d '' file; do
    # Skip hidden files and README
    [[ "$(basename "$file")" =~ ^\. ]] && continue
    [[ "$(basename "$file")" == "README.md" ]] && continue

    local target="$HOME/.$(basename "$file")"
    if ln -sf "$file" "$target" 2>/dev/null; then
      ((count++))
      log_info "Linked: $(basename "$file")"
    fi
  done < <(find "$DOTFILES_ROOT" -maxdepth 1 -type f -print0)

  log_success "Created $count symlinks"
}

# Update .zshenv
update_zshenv() {
  local zshenv="$HOME/.zshenv"
  touch "$zshenv"

  # Remove existing dotfiles entries
  sed -i.bak '/^export DOTFILES_/d' "$zshenv" 2>/dev/null || true
  rm -f "${zshenv}.bak"

  # Add new entries
  cat >> "$zshenv" << EOF
export DOTFILES_ROOT="$DOTFILES_ROOT"
export DOTFILES_PROFILE="$DOTFILES_PROFILE"
EOF
}

# Main installation
main() {
  echo "🚀 Dotfiles Installation"
  echo "======================="
  echo

  check_deps
  setup_repo
  create_links
  update_zshenv

  echo
  log_success "Installation complete!"
  log_info "Profile: $DOTFILES_PROFILE"
  log_info "Root: $DOTFILES_ROOT"
  echo
  log_info "Run: source ~/.zshrc"
  echo

  # Start new shell if interactive
  if [[ -t 0 && -t 1 ]] && command -v zsh &>/dev/null; then
    log_info "Starting new zsh shell..."
    exec zsh -l
  fi
}

main "$@"
