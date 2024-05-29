#!/usr/bin/env zsh

# GHQ - Manage remote repository clones
# https://github.com/x-motemen/ghq
export GHQ_ROOT="$HOME/Workspaces/src/"

# enhancd - an enhanced cd command integrated with a command line fuzzy finder based on UNIX concept
# https://github.com/babarot/enhancd
export ENHANCD_FILTER="fzf --preview 'eza -al --tree --level 1 \
        --group-directories-first --git-ignore \
        --header --git --no-user --no-time --no-filesize --no-permissions {}' \
        --preview-window right,50% --height 35% --reverse --ansi \
        :fzy :peco"
export ENHANCD_ENABLE_DOUBLE_DOT="false"
export ENHANCD_ENABLE_SINGLE_DOT="false"

# fzf - a command-line fuzzy finder
# https://github.com/junegunn/fzf
export FZF_DEFAULT_COMMAND="fd --type f"
export FZF_DEFAULT_OPTS="
        --height 75% --multi --reverse --margin=0,1 \
        --bind ctrl-f:page-down,ctrl-b:page-up,ctrl-/:toggle-preview \
        --bind pgdn:preview-page-down,pgup:preview-page-up \
        --preview 'bat --line-range :100 {}' \
        --marker='✚' --pointer='▶' --prompt='❯ ' --no-separator --scrollbar='█' \
        --color bg+:#262626,fg+:#dadada,hl:#f09479,hl+:#f09479 \
        --color border:#303030,info:#cfcfb0,header:#80a0ff,spinner:#36c692 \
        --color prompt:#87afff,pointer:#ff5189,marker:#f09479"
export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_CTRL_T_OPTS="--preview 'bat --line-range :100 {}'"
export FZF_ALT_C_COMMAND="fd --type d"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"

# nvm - node version manager
# https://github.com/nvm-sh/nvm
export NVM_DIR="$HOME/.dotfiles/data/nvm"
