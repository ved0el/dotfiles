# #!/usr/bin/env zsh

HISTSIZE=3000
SAVEHIST=3000
HISTFILE=~/.zsh_history

# History options
setopt SHARE_HISTORY          # Share history between sessions
setopt APPEND_HISTORY         # Append to history file
setopt INC_APPEND_HISTORY     # Add commands to history as they are typed
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt HIST_VERIFY           # Show command with history expansion to user before running it
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history
setopt HIST_FIND_NO_DUPS     # Don't display duplicates when searching
setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate

# Function to search command history using fzf
function fzf-history-search() {
  local selected=$(fc -l 1 | fzf --height 20 --reverse --margin=0,1 \
    --bind ctrl-f:page-down,ctrl-b:page-up \
    --marker='✚' --pointer='▶' --prompt='❯ ' --no-separator --scrollbar='█' \
    --color='bg+:#262626,fg+:#dadada,hl:#f95189,hl+:#f95189' \
    --color='border:#303030,info:#cfcfb0,header:#80a0ff,spinner:#36c692' \
    --color='prompt:#87afff,pointer:#ff5189,marker:#f09479')
  if [ -n "$selected" ]; then
    local num=$(echo "$selected" | awk '{print $1}')
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
}

# Create a new widget
zle -N fzf-history-search

# Bind the widget to Ctrl+R
bindkey '^R' fzf-history-search
