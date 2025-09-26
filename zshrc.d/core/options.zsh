#!/usr/bin/env zsh

# =============================================================================
# ZSH Options Configuration
# Modern shell behavior and feature settings
# =============================================================================

# Directory Navigation
setopt AUTO_CD              # cd to directory by typing its name
setopt AUTO_PUSHD          # automatically push directories to stack
setopt PUSHD_IGNORE_DUPS   # don't push duplicate directories
setopt PUSHD_MINUS         # exchanges meaning of +/- for pushd
setopt CDABLE_VARS         # expand the argument to cd if it's a variable

# Completion
setopt AUTO_MENU           # show completion menu on tab
setopt COMPLETE_IN_WORD    # allow completion in the middle of a word
setopt ALWAYS_TO_END       # move cursor to end after completion
setopt LIST_PACKED         # make completion lists more compact
setopt AUTO_LIST           # automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH    # add trailing slash for directories
setopt AUTO_PARAM_KEYS     # remove unneeded characters after completion

# Globbing
setopt EXTENDED_GLOB       # enable extended globbing
setopt GLOB_DOTS           # include hidden files in globbing
setopt NUMERIC_GLOB_SORT   # sort numbers numerically
setopt NO_CASE_GLOB        # case insensitive globbing

# History
setopt EXTENDED_HISTORY       # save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST # expire duplicates first when trimming history
setopt HIST_FIND_NO_DUPS      # don't display duplicates when searching
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries from history
setopt HIST_IGNORE_DUPS       # don't record duplicate entries
setopt HIST_IGNORE_SPACE      # don't record entries starting with space
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks
setopt HIST_SAVE_NO_DUPS      # don't save duplicates
setopt HIST_VERIFY            # show command with history expansion before running
setopt INC_APPEND_HISTORY     # add commands as they are typed
setopt SHARE_HISTORY          # share history between sessions

# Input/Output
setopt CORRECT             # enable command correction
setopt NO_FLOW_CONTROL     # disable flow control (Ctrl+S/Ctrl+Q)
setopt INTERACTIVE_COMMENTS # allow comments in interactive shells
setopt HASH_LIST_ALL       # hash entire command path first
setopt MULTIOS             # allow multiple redirections

# Job Control
setopt AUTO_RESUME         # resume jobs with just their name
setopt LONG_LIST_JOBS      # list jobs in long format
setopt NOTIFY              # report status of background jobs immediately

# Prompt
setopt PROMPT_SUBST        # enable parameter expansion in prompts

# Other
setopt NO_BEEP             # disable beeping
setopt NO_BG_NICE          # don't nice background jobs
setopt NO_HUP              # don't send HUP to jobs when shell exits
setopt IGNORE_EOF          # don't exit on EOF (Ctrl+D)
