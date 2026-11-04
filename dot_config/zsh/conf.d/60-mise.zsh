#!/usr/bin/env zsh
# mise: runtime / CLI-tool version manager (base owns it). No-ops if mise isn't installed.
# Must run before 75-tools.zsh so mise tool shims are on PATH.
# NOT cache_eval: `mise activate` bakes the current PATH into its output, so a cached copy
# restores a stale PATH in every new shell (a removed /opt/zerobrew stayed on it). ~10 ms.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
