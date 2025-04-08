#!/usr/bin/env zsh

# =============================================================================
# fzf Installation Script
# =============================================================================

# Package information
PACKAGE_NAME="fzf"
PACKAGE_DESC="A command-line fuzzy finder"

# Installation methods
typeset -A install_methods
install_methods=(
  [brew]="brew install fzf"
  [apt]="sudo apt install -y fzf"
  [pacman]="sudo pacman -S --noconfirm fzf"
  [custom]="git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all"
)

# Pre-installation commands
pre_install() {
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
}

# Post-installation commands
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_success "$PACKAGE_NAME is already installed"
  fi
}

# Initialization function
init() {
  return
}

# Main installation flow
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package $PACKAGE_NAME $PACKAGE_DESC "${(@kv)install_methods}"
  post_install
else
  init
fi
