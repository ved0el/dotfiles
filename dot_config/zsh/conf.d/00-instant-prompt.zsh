#!/usr/bin/env zsh
# powerlevel10k instant prompt — MUST load first, before anything that outputs.
# As 00-* it is the first file the conf.d loader sources.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
