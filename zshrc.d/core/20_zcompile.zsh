#!/usr/bin/env zsh

# Zsh file compilation for faster subsequent loads (deferred, quiet)
if [[ -z "$ZSHRC_COMPILED" ]]; then
    export ZSHRC_COMPILED=1

    _dotfiles_zcompile_update() {
        setopt localoptions null_glob

        # Ensure DOTFILES_ROOT is set
        [[ -z "${DOTFILES_ROOT:-}" ]] && return 0
        [[ ! -d "$DOTFILES_ROOT" ]] && return 0

        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        local stamp_file="$cache_dir/compile.stamp"
        local max_age="${DOTFILES_ZCOMPILE_MAX_AGE:-86400}"  # default: 24h (24 hours)
        local now_ts last_compile_ts age_diff

        # Create cache directory if needed
        mkdir -p "$cache_dir" &>/dev/null

        # Get current timestamp (zsh built-in, no OS dependency)
        now_ts=$EPOCHSECONDS

        # Read last compilation timestamp from stamp file
        if [[ -f "$stamp_file" ]]; then
            last_compile_ts=$(< "$stamp_file" 2>/dev/null)
            # Validate timestamp is numeric
            [[ "$last_compile_ts" =~ ^[0-9]+$ ]] || last_compile_ts=0
        else
            last_compile_ts=0
        fi

        # Calculate age difference
        age_diff=$((now_ts - last_compile_ts))

        # Skip if cache is still fresh (less than max_age seconds old)
        if (( age_diff < max_age )); then
            return 0
        fi

        # Show message only in verbose mode
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "🔧 Updating .zwc cache (zcompile)"

        # Gather files to compile
        local files
        files=(
            "$DOTFILES_ROOT"/zshrc.d/**/*.zsh(N)
            "$DOTFILES_ROOT"/zshrc(N)
            "$DOTFILES_ROOT"/p10k.zsh(N)
        )

        # Compile files that need updating
        local f compiled_count=0
        for f in "$files[@]"; do
            # Compile if file exists and either .zwc doesn't exist or source is newer
            if [[ -f "$f" && ( ! -f "$f.zwc" || "$f" -nt "$f.zwc" ) ]]; then
                zcompile "$f" &>/dev/null && ((compiled_count++))
            fi
        done

        # Update stamp file with current timestamp
        echo "$now_ts" > "$stamp_file" 2>/dev/null

        # Show success message only in verbose mode
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ .zwc cache updated ($compiled_count files)"
    }

    # Run in background to keep interactive startup fast
    # Redirect stderr to suppress job control messages ([N] PID)
    # Keep stdout for verbose mode messages
    (
        _dotfiles_zcompile_update
    ) 2>/dev/null &!
fi
