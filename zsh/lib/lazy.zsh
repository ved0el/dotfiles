#!/usr/bin/env zsh

# =============================================================================
# Lazy Loader Library — defer heavy tool initialization until first use
# =============================================================================

# Usage: create_lazy_wrapper "cmd" "load_func" [extra_cmds...]
#
# Registers a shell function wrapper for `cmd` that:
#   1. Intercepts the first call
#   2. Runs `load_func` (the real initialization)
#   3. Removes itself (real binary takes over for `cmd`)
#   4. Re-invokes the original command with original args
#
# Note: extra_cmds wrappers stay registered and call load_func on every
# invocation. load_func must have an idempotency guard at the top.
create_lazy_wrapper() {
    local cmd="$1"
    local load_func="$2"
    shift 2
    local additional_cmds=("$@")

    if [[ -z "$cmd" || -z "$load_func" ]]; then
        echo "ERROR: create_lazy_wrapper requires command name and load function" >&2
        return 1
    fi

    if [[ ! "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid command name: $cmd" >&2
        return 1
    fi

    if ! typeset -f "$load_func" >/dev/null; then
        echo "ERROR: Load function not found: $load_func" >&2
        return 1
    fi

    # Main command wrapper: self-destructs after first use
    # After load_func succeeds, two cases:
    #   binary tool        — whence -p finds it in PATH; unfunction wrapper, call binary
    #   shell function tool — load_func redefined cmd (e.g. nvm.sh defined nvm());
    #                         call directly, do NOT unfunction (removes real function)
    # NOTE: command -v in zsh matches functions too, so we use whence -p (PATH-only)
    eval "
${cmd}() {
    if ${load_func}; then
        if whence -p ${cmd} >/dev/null 2>&1; then
            unfunction ${cmd} 2>/dev/null || true
            command ${cmd} \"\$@\"
        elif typeset -f ${cmd} >/dev/null 2>&1; then
            ${cmd} \"\$@\"
        else
            echo 'ERROR: ${cmd} not available after lazy loading' >&2
            return 1
        fi
    else
        echo 'ERROR: Failed to lazy load ${cmd}' >&2
        return 1
    fi
}
"

    # Extra command wrappers: stay registered (load_func must be idempotent)
    for extra_cmd in "${additional_cmds[@]}"; do
        if [[ ! "$extra_cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "WARNING: Skipping invalid command name: $extra_cmd" >&2
            continue
        fi
        eval "
${extra_cmd}() {
    if ${load_func}; then
        if command -v ${extra_cmd} >/dev/null 2>&1; then
            command ${extra_cmd} \"\$@\"
        else
            echo 'ERROR: ${extra_cmd} not available after lazy loading' >&2
            return 1
        fi
    else
        echo 'ERROR: Failed to lazy load for ${extra_cmd}' >&2
        return 1
    fi
}
"
    done

    return 0
}
