#!/usr/bin/env zsh

# =============================================================================
# Custom FZF History Search - Core functionality
# =============================================================================

# Custom fzf history search function
fzf_history_search() {
    local selected_command
    
    # Use fzf to search through command history
    # - fc -lnr: list commands in reverse chronological order
    # - -2147483648: show all history (max int)
    # - --no-sort: don't sort results (keep chronological order)
    # - --reverse: reverse display order
    # - --height 40%: use 40% of terminal height
    # - --border: show border around fzf
    # - --prompt: custom prompt
    # - --query: pre-fill with current buffer content
    # - --bind: bind Ctrl+R to toggle sort
    selected_command=$(fc -lnr -2147483648 | fzf \
        --no-sort \
        --reverse \
        --height 40% \
        --border \
        --prompt='History: ' \
        --query="$BUFFER" \
        --bind='ctrl-r:toggle-sort' \
        --color='bg+:#262626,fg+:#f0dada,hl:#f09479,hl+:#f09479' \
        --color='marker:#f09479,spinner:#f09479,header:#f09479,info:#f0dada' \
        --color='prompt:#f0dada,pointer:#f09479')
    
    # If a command was selected, put it in the buffer
    if [[ -n "$selected_command" ]]; then
        BUFFER="$selected_command"
        CURSOR=$#BUFFER
    fi
    
    # Reset the prompt to show the new buffer
    zle reset-prompt
}

# Create zle widget for the history search function
zle -N fzf_history_search

# Bind Ctrl+R to our custom history search (override default)
bindkey -M emacs '^R' fzf_history_search
bindkey -M viins '^R' fzf_history_search
bindkey -M vicmd '^R' fzf_history_search

# Optional: Also bind Ctrl+S for forward history search
fzf_history_search_forward() {
    local selected_command
    
    selected_command=$(fc -ln 1 | fzf \
        --no-sort \
        --reverse \
        --height 40% \
        --border \
        --prompt='Forward History: ' \
        --query="$BUFFER" \
        --color='bg+:#262626,fg+:#f0dada,hl:#f09479,hl+:#f09479' \
        --color='marker:#f09479,spinner:#f09479,header:#f09479,info:#f0dada' \
        --color='prompt:#f0dada,pointer:#f09479')
    
    if [[ -n "$selected_command" ]]; then
        BUFFER="$selected_command"
        CURSOR=$#BUFFER
    fi
    
    zle reset-prompt
}

zle -N fzf_history_search_forward
bindkey -M emacs '^S' fzf_history_search_forward
bindkey -M viins '^S' fzf_history_search_forward
bindkey -M vicmd '^S' fzf_history_search_forward
