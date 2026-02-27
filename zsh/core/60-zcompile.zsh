#!/usr/bin/env zsh

# =============================================================================
# Background .zwc compilation — runs at most once per 24h
# Keeps startup fast by pre-compiling zsh files to bytecode
# =============================================================================

if [[ -z "$ZSHRC_COMPILED" ]]; then
    export ZSHRC_COMPILED=1

    _dotfiles_zcompile_update() {
        setopt localoptions null_glob

        [[ -z "${DOTFILES_ROOT:-}" ]] && return 0
        [[ ! -d "$DOTFILES_ROOT" ]] && return 0

        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        local stamp_file="$cache_dir/compile.stamp"
        local max_age="${DOTFILES_ZCOMPILE_MAX_AGE:-86400}"

        mkdir -p "$cache_dir" &>/dev/null

        local now_ts last_compile_ts age_diff
        now_ts=$EPOCHSECONDS

        if [[ -f "$stamp_file" ]]; then
            last_compile_ts=$(< "$stamp_file" 2>/dev/null)
            [[ "$last_compile_ts" =~ ^[0-9]+$ ]] || last_compile_ts=0
        else
            last_compile_ts=0
        fi

        age_diff=$((now_ts - last_compile_ts))
        (( age_diff < max_age )) && return 0

        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "Updating .zwc cache (zcompile)"

        local files
        files=(
            "$DOTFILES_ROOT"/zsh/**/*.zsh(N)
            "$DOTFILES_ROOT"/zshrc(N)
            "$DOTFILES_ROOT"/p10k.zsh(N)
        )

        local f compiled_count=0
        for f in "$files[@]"; do
            if [[ -f "$f" && ( ! -f "$f.zwc" || "$f" -nt "$f.zwc" ) ]]; then
                zcompile "$f" &>/dev/null && ((compiled_count++))
            fi
        done

        echo "$now_ts" > "$stamp_file" 2>/dev/null
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo ".zwc cache updated ($compiled_count files)"
    }

    ( _dotfiles_zcompile_update ) 2>/dev/null &!
fi
