#!/usr/bin/env zsh

# Background zcompile with verbose support (completely silent - no job notifications)
ensure_zcompiled() {
    local file="$1"
    local compiled="$file.zwc"
    if [[ ! -r "$compiled" || "$file" -nt "$compiled" ]]; then
        # Run zcompile synchronously to avoid background jobs
        zcompile "$file" &>/dev/null 2>&1
    fi
}

if [[ -z "$ZSHRC_COMPILED" ]]; then
    export ZSHRC_COMPILED=1
    
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
        echo "✅ Compiling zsh files for faster loading"
    fi
    
    # Run the entire compilation process synchronously to avoid background jobs
    (
        # Suppress all output and job notifications
        setopt no_notify
        local files=(
            "$DOTFILES_ROOT/zshrc"
            "$DOTFILES_ROOT"/zshrc.d/**/*.zsh(N)
        )
        for file in "${files[@]}"; do
            [[ -f "$file" ]] && ensure_zcompiled "$file"
        done
    ) &>/dev/null 2>&1
fi
