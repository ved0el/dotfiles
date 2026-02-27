#!/usr/bin/env zsh

# Disable beeps
setopt NO_BEEP
setopt NO_HIST_BEEP
setopt NO_LIST_BEEP

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Globbing and expansion
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
# NOTE: GLOB_COMPLETE removed — it breaks interactive tab completion by
# treating Tab input as glob patterns instead of prefix completion.

# Job control
setopt AUTO_CONTINUE
setopt LONG_LIST_JOBS

# Input/Output
setopt DVORAK
setopt NO_FLOW_CONTROL

# Prompt
setopt PROMPT_SUBST
setopt TRANSIENT_RPROMPT

# Script and functions
setopt C_BASES
setopt OCTAL_ZEROES
setopt RC_EXPAND_PARAM
setopt NO_BAD_PATTERN
setopt NO_BANG_HIST
