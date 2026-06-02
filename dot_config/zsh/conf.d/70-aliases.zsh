#!/usr/bin/env zsh
# General aliases. Each block self-gates on `command -v <tool>`, so an alias is only
# defined when its tool is actually installed (same rule as 75-tools.zsh).

# ── chezmoi (dotfiles manager) ───────────────────────────────────────────────
if command -v chezmoi >/dev/null 2>&1; then
  alias cz='chezmoi'
  alias cza='chezmoi apply'        # apply changes to $HOME
  alias cze='chezmoi edit'         # edit a managed file in $EDITOR
  alias czu='chezmoi update'       # git pull, then apply
  alias czd='chezmoi diff'         # show what apply would change
  alias czs='chezmoi status'       # short per-file status
  alias czcd='chezmoi cd'          # cd into the source repo (to commit/push)
fi
