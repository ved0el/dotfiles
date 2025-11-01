#!/usr/bin/env zsh

# =============================================================================
# Lazy Loader Library - Defer loading of heavy packages until first use
# =============================================================================

# -----------------------------------------------------------------------------
# Create lazy wrapper for a command
# Usage: create_lazy_wrapper "command" "load_function" [commands...]
# -----------------------------------------------------------------------------
create_lazy_wrapper() {
    local cmd="$1"
    local load_func="$2"
    shift 2
    local additional_cmds=("$@")

    # Create lazy wrapper for the main command
    eval "${cmd}() {
        ${load_func}
        unfunction ${cmd}
        ${cmd} \"\$@\"
    }"

    # Create lazy wrappers for additional commands if provided
    for extra_cmd in "${additional_cmds[@]}"; do
        eval "${extra_cmd}() {
            ${load_func}
            command ${extra_cmd} \"\$@\"
        }"
    done
}
