#!/usr/bin/env bash
set -euo pipefail

bold() { printf "\033[1m%s\033[0m" "$*"; }
green() { printf "\033[32m%s\033[0m" "$*"; }
yellow() { printf "\033[33m%s\033[0m" "$*"; }
red() { printf "\033[31m%s\033[0m" "$*"; }

log_info()    { printf "[%s] %s\n" "INFO" "$*"; }
log_warn()    { printf "[%s] %s\n" "WARN" "$(yellow "$*")"; }
log_error()   { printf "[%s] %s\n" "ERROR" "$(red "$*")"; }
log_success() { printf "[%s] %s\n" "OK" "$(green "$*")"; }

ensure_running_bash() {
  if [ -z "${BASH_VERSION:-}" ]; then
    log_error "Please run with bash"; exit 1;
  fi
}

require_tools() {
  local missing=()
  for t in "$@"; do
    if ! command -v "$t" >/dev/null 2>&1; then missing+=("$t"); fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing tools: ${missing[*]}"; exit 1;
  fi
}

backup_file() {
  local path="$1"
  local backup_dir="$HOME/.dotfiles_backup"
  if [ -e "$path" ] || [ -L "$path" ]; then
    mkdir -p "$backup_dir"
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    mv -f "$path" "$backup_dir/$(basename "$path").$ts"
    log_warn "Backed up $(basename "$path") to $backup_dir"
  fi
}

link_file() {
  local source="$1"; shift
  local target="$1"; shift
  backup_file "$target"
  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
  log_success "Linked $(basename "$source") -> $target"
}

