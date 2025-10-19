#!/usr/bin/env zsh

# =============================================================================
# Ultra-Fast Shell Performance Options - Maximum Speed Configuration
# =============================================================================

# Disable completion system warnings
export ZSH_DISABLE_COMPFIX=true

# Minimal history settings for maximum speed
HISTSIZE=3000          # Reduced from 5000
SAVEHIST=3000          # Reduced from 5000
HISTFILE=~/.zsh_history

# Disable ALL slow features for maximum performance
unsetopt correct correct_all auto_menu menu_complete flow_control beep list_beep
unsetopt auto_cd auto_pushd pushd_ignore_dups pushd_silent cdable_vars
unsetopt hist_verify hist_save_no_dups hist_expire_dups_first
unsetopt auto_list auto_menu list_ambiguous list_packed list_rows_first
unsetopt auto_param_slash auto_param_keys auto_remove_slash
unsetopt complete_in_word complete_aliases
unsetopt glob_complete glob_dots glob_subst case_glob case_match
unsetopt hash_cmds hash_dirs hash_list_all
unsetopt multios multibyte
unsetopt notify bg_nice check_jobs hup
unsetopt path_dirs path_script
unsetopt print_exit_value print_eight_bit
unsetopt prompt_cr prompt_sp transient_rprompt
unsetopt rm_star_silent rm_star_wait
unsetopt sh_file_expansion sh_glob
unsetopt single_line_zle
unsetopt sun_keyboard_hack

# Enable only essential history features (minimal set)
setopt hist_ignore_dups hist_ignore_space hist_reduce_blanks
setopt inc_append_history share_history
setopt hist_find_no_dups hist_ignore_all_dups

# Fast globbing options
setopt null_glob extended_glob
