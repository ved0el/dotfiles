#!/usr/bin/env zsh
# sheldon: zsh plugins; cache keyed on plugins.toml. Sourced BEFORE 50-completions
# so plugins that extend $fpath (zsh-completions) are picked up; deferred plugins
# that need compinit (fzf-tab) fire after prompt. No-ops if sheldon isn't installed.
if command -v sheldon >/dev/null 2>&1; then
  _toml="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
  _cache="$ZSH_CACHE_DIR/sheldon.zsh"
  if [[ ! -r "$_cache" || "$_toml" -nt "$_cache" ]]; then
    sheldon source >| "$_cache"
    zcompile "$_cache" 2>/dev/null
  fi
  source "$_cache"
  unset _toml _cache

  # history-substring-search keybindings (its widgets exist once sourced above).
  bindkey '^[[A' history-substring-search-up    # Up
  bindkey '^[[B' history-substring-search-down  # Down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi
