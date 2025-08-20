#!/usr/bin/env zsh

# Performance-critical options for fast shell startup
if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
  echo "✅ Performance options loaded"
fi

export ZSH_DISABLE_COMPFIX=true
# unsetopt correct correct_all auto_menu menu_complete flow_control beep list_beep
# unsetopt nomatch glob_subst cdable_vars auto_list auto_param_keys
# unsetopt auto_param_slash auto_pushd chase_links chase_dots equals
# unsetopt hist_allow_clobber hist_expire_dups_first hist_find_no_dups
# unsetopt hist_no_functions hist_no_store hist_save_no_dups
# unsetopt bash_auto_list list_ambiguous list_packed list_rows_first list_types
# unsetopt menu_complete rec_exact pushd_silent pushd_to_home no_notify

# setopt hist_ignore_dups hist_ignore_space hist_reduce_blanks hist_verify
# setopt inc_append_history share_history
# setopt pushd_ignore_dups pushd_minus auto_remove_slash auto_resume
# setopt extended_glob glob_dots glob_star_short

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
