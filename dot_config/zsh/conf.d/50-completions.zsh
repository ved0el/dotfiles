#!/usr/bin/env zsh
# completions: rebuild the dump at most once a day, byte-compile in the background.
autoload -Uz compinit
_zcompdump="$ZSH_CACHE_DIR/zcompdump"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"            # >24h old → full rebuild (security check)
else
  compinit -C -d "$_zcompdump"         # fresh → skip the check, use cache
fi
{ [[ -s "$_zcompdump" && (! -s "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc") ]] && zcompile "$_zcompdump"; } &!
unset _zcompdump

# Native menu completion (fzf-tab removed): arrow-key selectable, case-insensitive.
# Coloring comes from list-colors, set in 75-tools.zsh after vivid exports LS_COLORS
# (zstyles are read at completion time, so module order doesn't matter here).
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
