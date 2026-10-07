#!/usr/bin/env zsh
# General aliases. Each block self-gates on `command -v <tool>`, so an alias is only
# defined when its tool is actually installed (same rule as 75-tools.zsh).

# ── navigation / listing (same names in the pwsh profile) ────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias lsal='ls -al'   # eza when installed (75-tools.zsh aliases ls)
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
alias reload='exec zsh'
alias path='print -l $path'
alias e='${EDITOR:-micro}'

# ── git (forgit already owns ga/gd/glo/gcb/…) ────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias gl='git pull'
alias gp='git push'
alias gsw='git switch'
alias glg='git log --oneline --graph -20'

# ── tool swaps, Claude, tmux ─────────────────────────────────────────────────
# bat only on a terminal (its config forces --color=always: a pipe gets real cat), and not in
# Claude's tool shell (it snapshots functions): its `cat` must take cat's flags.
if [[ -z "$CLAUDECODE" ]] && command -v bat >/dev/null 2>&1; then
  cat() { if [[ -t 1 ]]; then bat --paging=never "$@"; else command cat "$@"; fi; }
fi
command -v btm >/dev/null 2>&1 && alias top='btm'
alias clc='claude --continue'
alias clr='claude --resume'
command -v tmux >/dev/null 2>&1 && alias tm='tmux attach 2>/dev/null || tmux new -s main'

# ── chezmoi (dotfiles manager) ───────────────────────────────────────────────
if command -v chezmoi >/dev/null 2>&1; then
  alias cz='chezmoi'
  alias cza='chezmoi apply'        # apply changes to $HOME
  alias cze='chezmoi edit'         # edit a managed file in $EDITOR
  alias czu='chezmoi update'       # git pull, then apply
  alias czd='chezmoi diff'         # show what apply would change
  alias czs='chezmoi status'       # short per-file status
  alias czra='chezmoi re-add'      # capture $HOME edits back into the source repo
  alias czcd='chezmoi cd'          # cd into the source repo (to commit/push)
fi
