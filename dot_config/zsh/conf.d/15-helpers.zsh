#!/usr/bin/env zsh
# cache helpers — MUST load before sheldon/completions/mise (they use ZSH_CACHE_DIR
# and cache_eval).
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# cache_eval <command> [args...] — run it, cache+byte-compile the output, source it;
# regenerated only when the command's binary changes. No-ops if the command is
# absent (so it follows the "only configure installed tools" rule). Used by mise and
# conf.d snippets. Example: cache_eval mise activate zsh
cache_eval() {
  command -v "$1" >/dev/null 2>&1 || return 0
  local name="$1" cache="$ZSH_CACHE_DIR/$1.zsh" bin; shift
  bin="$(command -v "$name")"
  if [[ ! -r "$cache" || "$bin" -nt "$cache" ]]; then
    "$name" "$@" >| "$cache" 2>/dev/null
    zcompile "$cache" 2>/dev/null
  fi
  source "$cache"
}
