#!/usr/bin/env zsh

# =============================================================================
# Core environment and shell options
# =============================================================================

# Environment
export TERM="xterm-256color"
[[ ":$PATH:" != *":$DOTFILES_ROOT/bin:"* ]] && export PATH="$PATH:$DOTFILES_ROOT/bin"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]]   && export PATH="$PATH:$HOME/.local/bin"
# Disable beeps
setopt NO_BEEP NO_HIST_BEEP NO_LIST_BEEP

# Directory navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Globbing and expansion
setopt EXTENDED_GLOB NO_CASE_GLOB NUMERIC_GLOB_SORT
# NOTE: GLOB_COMPLETE intentionally omitted — breaks interactive tab completion
# (treats Tab input as glob patterns instead of prefix completion)

# Job control
setopt AUTO_CONTINUE LONG_LIST_JOBS

# Input/Output
setopt DVORAK NO_FLOW_CONTROL

# Prompt
setopt PROMPT_SUBST TRANSIENT_RPROMPT

# Script and functions
setopt C_BASES OCTAL_ZEROES RC_EXPAND_PARAM NO_BAD_PATTERN NO_BANG_HIST
