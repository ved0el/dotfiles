function attach_tmux_session_if_needed() {
    # Check if we have a valid terminal
        if tmux has-session 2>/dev/null; then
            # If sessions exist, attach to the first available one
            tmux attach-session
        else
            # If no sessions exist, create a new one
            tmux new-session
        fi
}

# Only run in interactive shell, when not already in tmux, and in a valid terminal
if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then
    attach_tmux_session_if_needed
fi
