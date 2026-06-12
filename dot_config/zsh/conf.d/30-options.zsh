#!/usr/bin/env zsh
# shell options — EXTENDED_GLOB must be set before 50-completions uses (#qN.mh+24).
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS NO_BEEP
# Directory stack: `cd -<Tab>` lists recent dirs to jump back to (complements
# zoxide's frecent jumps). PUSHD_SILENT/IGNORE_DUPS keep the stack quiet + dedup'd.
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
