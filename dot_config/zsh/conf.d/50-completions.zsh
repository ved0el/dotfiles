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

# fzf-tab replaces the Tab menu with an fzf picker (plugin in sheldon, deferred).
# It REQUIRES `menu no` — never `menu select`. Entry coloring comes from list-colors
# (vivid LS_COLORS, set in 75-tools.zsh); use-fzf-default-opts makes the picker inherit
# the catppuccin FZF_DEFAULT_OPTS. All zstyles are read at completion time, so order
# vs the deferred plugin load and the 75-tools LS_COLORS export doesn't matter.
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*:descriptions' format '[%d]'           # group headers in the picker
zstyle ':completion:*' group-name ''
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# Force a tall window even when a completion has only 1-2 candidates. fzf-tab sizes
# height to min(max(candidates, fzf-min-height), LINES*2/3); the default min of 0
# collapses the picker — and its right-side preview — to a single line. A large min
# pins it to the 2/3-screen cap so previews get full height (like ctrl-r/ctrl-t).
zstyle ':fzf-tab:*' fzf-min-height 100
zstyle ':fzf-tab:*' switch-group '<' '>'                    # < / > cycle completion groups
# Directory previews (cd + zoxide jump): a one-level eza tree.
zstyle ':fzf-tab:complete:cd:*'         fzf-preview 'eza --tree --level=1 --color=always --icons=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=1 --color=always --icons=always $realpath'
# Generic preview: eza tree for dirs, bat (first 200 lines) for files.
zstyle ':fzf-tab:complete:*:*'          fzf-preview '[ -d "$realpath" ] && eza --tree --level=1 --color=always --icons=always "$realpath" || bat --style=numbers --color=always --line-range=:200 "$realpath" 2>/dev/null'
