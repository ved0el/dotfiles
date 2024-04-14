#!/usr/bin/env zsh

# Check if there are any files with the specified format
if ls "$ZSHRC_GLOBAL_CONFIG_DIR"/*_l.zsh &> /dev/null; then
    # Loop through files in $ZSHRC_GLOBAL_CONFIG_DIR
    for file in "$ZSHRC_GLOBAL_CONFIG_DIR"/*_l.zsh; do
        # Check if file exists and is readable
        if [[ -f "$file" && -r "$file" ]]; then
            source "$file"
        else
            echo "Error: \033[1;36m$file\033[m not found or not readable."
        fi
    done
fi
