#!/usr/bin/env zsh

# Zsh file compilation for faster subsequent loads (deferred, quiet)
if [[ -z "$ZSHRC_COMPILED" ]]; then
    export ZSHRC_COMPILED=1

    _dotfiles_zcompile_update() {
        setopt localoptions null_glob

        local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        local stamp_file="$cache_dir/compile.stamp"
        local max_age="${DOTFILES_ZCOMPILE_MAX_AGE:-86400}"  # default: 24h
        local now_ts stamp_mtime

        mkdir -p "$cache_dir" &>/dev/null

        now_ts=$(date +%s)
        stamp_mtime=$(stat -f %m "$stamp_file" 2>/dev/null || echo 0)

        # Skip if recently compiled
        if (( now_ts - stamp_mtime < max_age )); then
            return 0
        fi

        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "🔧 Updating .zwc cache (zcompile)"

        # Gather files to compile
        local files
        files=(
            "$DOTFILES_ROOT"/zshrc.d/**/*.zsh(N)
            "$DOTFILES_ROOT"/zshrc(N)
            "$DOTFILES_ROOT"/p10k.zsh(N)
        )

        local f
        for f in "$files[@]"; do
            [[ -f "$f" && ( ! -f "$f.zwc" || "$f" -nt "$f.zwc" ) ]] && zcompile "$f" &>/dev/null
        done

        : > "$stamp_file" 2>/dev/null
        [[ "${DOTFILES_VERBOSE:-false}" == "true" ]] && echo "✅ .zwc cache updated"
    }

    # Run in background to keep interactive startup fast
    (
        _dotfiles_zcompile_update
    ) & disown
fi
