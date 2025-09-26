#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"

link_tree() {
  local src_dir="$1"; shift
  local dst_home="$HOME" # destination root is home
  find "$src_dir" -mindepth 1 -maxdepth 2 -type f | while read -r file; do
    case "$file" in
      *.swp|*.tmp|*.bak) continue;;
    esac
    local name
    name="$(basename "$file")"
    case "$name" in
      .DS_Store) continue;;
    esac
    local rel
    rel="${file#"$src_dir/"}"
    local target
    target="$dst_home/${rel##*/}"
    link_file "$file" "$target"
  done
}

