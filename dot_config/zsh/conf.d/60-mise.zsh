#!/usr/bin/env zsh
# mise: runtime / CLI-tool version manager (base owns it). cache_eval no-ops if mise
# isn't installed. Must run before 75-tools.zsh so mise tool shims are on PATH.
cache_eval mise activate zsh
