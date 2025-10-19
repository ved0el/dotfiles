#!/usr/bin/env zsh

# Ultra-fast shell startup options
export ZSH_DISABLE_COMPFIX=true

# Minimal history settings for speed
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

# Disable slow features
unsetopt correct correct_all auto_menu menu_complete flow_control beep list_beep
unsetopt auto_cd auto_pushd pushd_ignore_dups
unsetopt hist_verify hist_save_no_dups

# Enable only essential history features
setopt hist_ignore_dups hist_ignore_space hist_reduce_blanks
setopt inc_append_history share_history

# Disable completion system during startup (load later)
unsetopt auto_list auto_menu list_ambiguous
