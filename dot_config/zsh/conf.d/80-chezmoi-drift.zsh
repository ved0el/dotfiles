#!/usr/bin/env zsh
# chezmoi drift nudge — warn ONCE per shell if any managed file differs from its
# source, so an edit made directly in $HOME doesn't silently go un-synced. The probe
# runs in the BACKGROUND at startup (never blocks the prompt); a one-shot precmd
# surfaces the result on a later prompt, then disarms itself.
#
# `create_` files (e.g. ~/.claude/settings.json) are untracked by design, so they
# never trigger this — chezmoi status ignores them. Fix drift with `czra`
# (chezmoi re-add) to capture $HOME edits, or `cze`/`cza` to edit via the source.
if command -v chezmoi >/dev/null 2>&1; then
  _CZ_DRIFT_FLAG="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/chezmoi-drift.$$"

  # Background probe: write the flag only when there's drift. Disowned so there's no
  # job-control message and zero added startup latency.
  { chezmoi status 2>/dev/null | grep -q . && : >| "$_CZ_DRIFT_FLAG" } &!

  _chezmoi_drift_nudge() {
    [[ -f "$_CZ_DRIFT_FLAG" ]] || return            # not ready / no drift → check again next prompt
    command rm -f "$_CZ_DRIFT_FLAG"
    add-zsh-hook -d precmd _chezmoi_drift_nudge      # one-shot: never nag twice in one shell
    print -P "%F{yellow}⚠ chezmoi:%f managed dotfiles drifted from source — %F{cyan}czs%f to view, %F{cyan}czra%f to capture"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _chezmoi_drift_nudge
fi
