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

    # Validate inputs
    if [[ -z "$cmd" || -z "$load_func" ]]; then
        echo "ERROR: create_lazy_wrapper requires command name and load function" >&2
        return 1
    fi

    # Validate command name contains only safe characters (alphanumeric, underscore, hyphen)
    if [[ ! "$cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid command name: $cmd" >&2
        return 1
    fi

    # Validate load function exists
    if ! typeset -f "$load_func" >/dev/null; then
        echo "ERROR: Load function not found: $load_func" >&2
        return 1
    fi

    # Create lazy wrapper for the main command using safer function definition
    eval "
${cmd}() {
    # Call the load function
    if ${load_func}; then
        # Only unfunction if the function still exists and load succeeded
        if typeset -f ${cmd} >/dev/null 2>&1; then
            unfunction ${cmd} 2>/dev/null || true
        fi
        # Re-run the command if it exists
        if command -v ${cmd} >/dev/null 2>&1; then
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

    # Create lazy wrappers for additional commands if provided
    for extra_cmd in "${additional_cmds[@]}"; do
        # Validate additional command name
        if [[ ! "$extra_cmd" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "WARNING: Skipping invalid command name: $extra_cmd" >&2
            continue
        fi

        eval "
${extra_cmd}() {
    # Load the main functionality first
    if ${load_func}; then
        # Execute the actual command
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
