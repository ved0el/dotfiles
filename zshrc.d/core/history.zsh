# =============================================================================
# History Configuration
# =============================================================================

# History file location
HISTFILE=~/.zsh_history

# History size
HISTSIZE=10000
SAVEHIST=10000

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