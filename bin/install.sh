#!/usr/bin/env bash

set -uo pipefail

# =============================================================================
#  Constants
# =============================================================================
readonly REPO_URL="https://github.com/ved0el/dotfiles.git"
readonly DEFAULT_DOTFILES_ROOT="$HOME/.dotfiles"

# Return codes
readonly E_SUCCESS=0
readonly E_ERROR=1
readonly E_MENU_BACK=2

# Platform-specific settings
if [[ "$(uname)" == "Darwin" ]]; then
  readonly sed_in_place="''"
else
  readonly sed_in_place=""
fi

# =============================================================================
#  Helper Functions
# =============================================================================
clear_screen() { printf "\033c"; }

log_info()    { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }

show_header() {
  clear_screen
  cat << EOF
╭───────────────────────────────────────╮
│      Dotfiles Installer by ved0el     │
╰───────────────────────────────────────╯

Press 'h' for help, 'q' to quit
EOF
  echo
}

show_usage() {
  clear_screen
  cat << EOF
╭───────────────────────────────────────╮
│      Dotfiles Installer by ved0el     │
╰───────────────────────────────────────╯

Usage:
  ./install.sh                         # Interactive installation
  curl -fsSL <url> | bash              # Quick install
  curl -fsSL <url> | DOTFILES_* bash   # Install with overrides

Environment Variables:
  DOTFILES_ROOT    - Directory to clone dotfiles into (e.g., $HOME/.dotfiles)
  DOTFILES_PROFILE - Installation profile (e.g., "minimal", "server", "full")

Profiles:
  minimal  - Basic installation (default)
  server   - Shell + utilities (no development tools)
  full     - Full development machine setup

Press any key to continue...
EOF
  read -rsn1
}

# =============================================================================
#  Core Functions
# =============================================================================
update_zshenv() {
  local key="$1"
  local value="$2"
  local zshenv="$HOME/.zshenv"

  touch "$zshenv" || {
    log_error "Cannot create/access $zshenv"
    return "$E_ERROR"
  }

  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "/^export ${key}=/d" "$zshenv" 2>/dev/null || :
  else
    sed -i "/^export ${key}=/d" "$zshenv" 2>/dev/null || :
  fi

  echo "export ${key}=${value}" >> "$zshenv"
}

set_dotfiles_root() {
  if [[ -n "${DOTFILES_ROOT:-}" ]]; then
    if [[ ! "$DOTFILES_ROOT" =~ ^/ ]]; then
      DOTFILES_ROOT="$HOME/$DOTFILES_ROOT"
    fi

    if [[ -d "$DOTFILES_ROOT" ]] || mkdir -p "$DOTFILES_ROOT" 2>/dev/null; then
      log_info "Using directory: $DOTFILES_ROOT"
      update_zshenv "DOTFILES_ROOT" "$DOTFILES_ROOT"
      return $E_SUCCESS
    else
      log_error "Invalid directory provided in DOTFILES_ROOT"
      return $E_ERROR
    fi
  fi

  while true; do
    show_header
    log_info "Setting up dotfiles directory..."
    echo
    echo "Current directory: $DEFAULT_DOTFILES_ROOT"
    echo
    echo "1) Use default"
    echo "2) Set custom directory"
    echo
    echo -n "Choice [12hq]: "

    read -rsn1 choice
    echo
    case $choice in
      1)
        DOTFILES_ROOT="$DEFAULT_DOTFILES_ROOT"
        if mkdir -p "$DOTFILES_ROOT" 2>/dev/null; then
          update_zshenv "DOTFILES_ROOT" "$DOTFILES_ROOT"
          return $E_SUCCESS
        else
          log_error "Failed to create directory"
          sleep 1
        fi
        ;;
      2)
        echo -n "Enter directory path: "
        read -r custom_dir
        if [[ ! "$custom_dir" =~ ^/ ]]; then
          custom_dir="$HOME/$custom_dir"
        fi

        if mkdir -p "$custom_dir" 2>/dev/null; then
          DOTFILES_ROOT="$custom_dir"
          update_zshenv "DOTFILES_ROOT" "$DOTFILES_ROOT"
          return $E_SUCCESS
        else
          log_error "Invalid directory"
          sleep 1
        fi
        ;;
      h) show_usage ;;
      q) exit 0 ;;
      *) log_error "Invalid choice"; sleep 1 ;;
    esac
  done
}

set_profile() {
  if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
    case "${DOTFILES_PROFILE,,}" in
      full|server|minimal)
        export_profile "${DOTFILES_PROFILE,,}"
        return $E_SUCCESS
        ;;
      *)
        log_error "Invalid profile: $DOTFILES_PROFILE"
        export_profile "minimal"
        return $E_SUCCESS
        ;;
    esac
  fi

  while true; do
    show_header
    log_info "Select installation profile:"
    echo
    echo "1) Full (shell + dev + utils)"
    echo "2) Server (shell + utils)"
    echo "3) Minimal (shell only)"
    echo
    echo -n "Choice [123hq]: "

    read -rsn1 choice
    echo
    case $choice in
      1) export_profile "full"; return $E_SUCCESS ;;
      2) export_profile "server"; return $E_SUCCESS ;;
      3) export_profile "minimal"; return $E_SUCCESS ;;
      h) show_usage; continue ;;
      q) exit 0 ;;
      *) log_error "Invalid choice"; sleep 1 ;;
    esac
  done
}

export_profile() {
  export DOTFILES_PROFILE="$1"
  update_zshenv "DOTFILES_PROFILE" "$1"
  log_success "Profile set to $1"
}

check_dependencies() {
  local deps=(git curl sudo)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required dependencies:"
    printf '  • %s\n' "${missing[@]}"
    return $E_ERROR
  fi
}

setup_repository() {
  show_header
  log_info "Setting up repository..."

  if [[ -d "$DOTFILES_ROOT/.git" ]]; then
    log_info "Updating existing repository..."
    (cd "$DOTFILES_ROOT" && git pull) || {
      log_error "Failed to update repository"
      return $E_ERROR
    }
  else
    log_info "Cloning new repository..."
    git clone "$REPO_URL" "$DOTFILES_ROOT" || {
      log_error "Failed to clone repository"
      return $E_ERROR
    }
  fi

  return $E_SUCCESS
}

link_files() {
  show_header
  log_info "Creating symlinks..."

  if [[ ! -d "$DOTFILES_ROOT" ]]; then
    log_error "Source directory not found: $DOTFILES_ROOT"
    return $E_ERROR
  fi

  local count=0
  shopt -s nullglob
  while IFS= read -r file; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" =~ ^\.|\bREADME ]] && continue

    local target="$HOME/.$(basename "$file")"
    ln -sf "$file" "$target" && {
      ((count++))
      log_success "Linked: $target"
    }
  done < <(find "$DOTFILES_ROOT" -maxdepth 1 -type f)
  shopt -u nullglob

  log_success "Linked $count files"
  return $E_SUCCESS
}

do_uninstall() {
  if [[ -z "${DOTFILES_ROOT:-}" ]]; then
    if [[ -f "$HOME/.zshenv" ]]; then
      source "$HOME/.zshenv"
    fi
    DOTFILES_ROOT="${DOTFILES_ROOT:-$DEFAULT_DOTFILES_ROOT}"
  fi

  if [[ ! -d "$DOTFILES_ROOT" ]]; then
    log_error "Directory not found: $DOTFILES_ROOT"
    return $E_ERROR
  fi

  local count=0
  shopt -s nullglob
  while IFS= read -r file; do
    [[ ! -f "$file" ]] && continue
    local target="$HOME/.$(basename "$file")"
    if [[ -L "$target" ]]; then
      rm -f "$target"
      ((count++))
      log_success "Removed: $target"
    fi
  done < <(find "$DOTFILES_ROOT" -maxdepth 1 -type f)
  shopt -u nullglob

  if [[ -d "$DOTFILES_ROOT" ]]; then
    rm -rf "$DOTFILES_ROOT"
    log_success "Removed directory: $DOTFILES_ROOT"
  fi

  if [[ -f "$HOME/.zshenv" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' '/^export DOTFILES_/d' "$HOME/.zshenv"
    else
      sed -i '/^export DOTFILES_/d' "$HOME/.zshenv"
    fi
    log_success "Cleaned up environment variables"
  fi

  log_success "Uninstalled $count files"
  return $E_SUCCESS
}

show_uninstall_confirm() {
  while true; do
    show_header
    log_warning "Are you sure you want to uninstall dotfiles?"
    echo
    echo "This will:"
    echo "  • Remove all symlinks"
    echo "  • Delete the repository"
    echo "  • Clean up environment variables"
    echo
    echo "1) Yes, uninstall everything"
    echo "2) No, return to main menu"
    echo
    echo -n "Choice [12hq]: "

    read -rsn1 choice
    echo
    case $choice in
      1) do_uninstall; return $E_SUCCESS ;;
      2) return $E_MENU_BACK ;;
      h) show_usage; continue ;;
      q) exit 0 ;;
      *) log_error "Invalid choice"; sleep 1; continue ;;
    esac
  done
}

show_menu() {
  while true; do
    show_header
    echo "1) Install/Update"
    echo "2) Uninstall"
    echo
    echo -n "Choice [12hq]: "

    read -rsn1 choice
    echo
    case $choice in
      1)
        set_dotfiles_root || continue
        set_profile || continue
        setup_repository || continue
        link_files || continue
        return $E_SUCCESS
        ;;
      2)
        show_uninstall_confirm
        case $? in
          $E_MENU_BACK) continue ;;
          $E_SUCCESS) return $E_SUCCESS ;;
          *) continue ;;
        esac
        ;;
      h) show_usage; continue ;;
      q) exit 0 ;;
      *) log_error "Invalid choice"; sleep 1; continue ;;
    esac
  done
}

main() {
  if ! check_dependencies; then
    exit $E_ERROR
  fi

  if ! [[ -t 0 && -t 1 ]] && [[ -z "${DOTFILES_PROFILE:-}" ]]; then
    export DOTFILES_PROFILE="minimal"
  fi

  show_menu
  local status=$?

  if [[ $status -eq $E_SUCCESS ]]; then
    log_success "Operation completed successfully!"
    if command -v zsh >/dev/null 2>&1; then
      log_info "Starting new shell..."
      exec zsh -l
    fi
  fi

  exit $status
}

interactive_menu() {
  if ! [[ -t 0 && -t 1 ]]; then
    echo "No terminal detected. Running in non-interactive mode."
    main
    return
  fi

  while true; do
    show_header
    echo "1) Install/Update"
    echo "2) Uninstall"
    echo "h) Help"
    echo "q) Quit"
    echo
    echo -n "Choice: [12hq]"

    read -rp "" choice
    case $choice in
      1) main; break ;;
      2) do_uninstall; break ;;
      h) show_usage ;;
      q) exit 0 ;;
      *) log_error "Invalid choice, try again" ;;
    esac
  done
}


# Run the main logic depending on the execution type.
if [[ -n "${PS1:-}" ]]; then
  # Interactive execution (has a terminal/TTY)
  interactive_menu
elif [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  # Direct execution (e.g., ./install.sh)
  main
elif [[ -z "${BASH_SOURCE[0]:-}" ]]; then
  # Non-interactive execution (e.g., curl | bash)
  main
fi
