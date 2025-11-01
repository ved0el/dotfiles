#!/usr/bin/env zsh

export LANG="en_US.UTF-8"
export LC_ALL="C.UTF-8"

export DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
export DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-false}"

# Load core modules immediately
for core_file in "$DOTFILES_ROOT"/zshrc.d/core/*.zsh(N); do
  [[ -r "$core_file" ]] && source "$core_file"
done

# Load packages install helper
[[ -r "$DOTFILES_ROOT"/zshrc.d/lib/install_helper.zsh ]] && source "$DOTFILES_ROOT"/zshrc.d/lib/install_helper.zsh
[[ -r "$DOTFILES_ROOT"/zshrc.d/lib/lazy_load_wrapper.zsh ]] && source "$DOTFILES_ROOT"/zshrc.d/lib/lazy_load_wrapper.zsh



# Determine which package tiers to initialize based on profile
typeset -a __pkg_patterns
case "${DOTFILES_PROFILE}" in
  minimal) __pkg_patterns=('*_m_*.zsh') ;;
  server) __pkg_patterns=('*_m_*.zsh' '*_s_*.zsh') ;;
  develop) __pkg_patterns=('*_m_*.zsh' '*_s_*.zsh' '*_d_*.zsh') ;;
  *) __pkg_patterns=('*_m_*.zsh' '*_s_*.zsh' '*_d_*.zsh') ;;
esac

# Source package scripts matching the active profile; they should self-register lazy wrappers
for pattern in "$__pkg_patterns[@]"; do
  for pkg_file in "$DOTFILES_ROOT"/zshrc.d/pkg/$~pattern(N); do
    [[ -f "$pkg_file" ]] && source "$pkg_file"
  done
done
