#!/usr/bin/env zsh

# Zsh file compilation for faster loading (run once per session)
if [[ -z "$ZSHRC_COMPILED" ]]; then
    export ZSHRC_COMPILED=1

    # Compile zsh files in background for faster subsequent loads
    (
        for file in "$DOTFILES_ROOT"/zshrc.d/**/*.zsh(N); do
            [[ -f "$file" && (! -f "$file.zwc" || "$file" -nt "$file.zwc") ]] && zcompile "$file" &>/dev/null
        done
    ) &>/dev/null &
    disown 2>/dev/null
fi
