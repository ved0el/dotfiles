#!/usr/bin/env zsh

# Performance-critical options for fast shell startup
export ZSH_DISABLE_COMPFIX=true

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Performance options (commented for reference)
# These can be uncommented if needed for specific performance requirements
# unsetopt correct correct_all auto_menu menu_complete flow_control beep list_beep
# setopt hist_ignore_dups hist_ignore_space hist_reduce_blanks hist_verify
# setopt inc_append_history share_history
