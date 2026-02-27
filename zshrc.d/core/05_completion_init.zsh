#!/usr/bin/env zsh

# =============================================================================
# Completion Initialization
# Must run AFTER sheldon (which loads zsh-completions into fpath immediately)
# Must run BEFORE fzf-tab (which is deferred via sheldon)
# =============================================================================

# compinit is called in zshrc.d/pkg/100_m_sheldon.zsh AFTER sheldon sources
# zsh-completions, ensuring fpath is fully populated before the dump is built.

# =============================================================================
# Completion Styles
# =============================================================================

# Menu-based completion with selection highlight
zstyle ':completion:*' menu select

# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# Case-insensitive, then partial-word, then substring matching
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# Use colors in file completion (same palette as ls)
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Disable sort for git checkout (keeps branch order meaningful)
zstyle ':completion:*:git-checkout:*' sort false

# fzf-tab: switch between groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'
