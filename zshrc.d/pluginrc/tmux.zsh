function attach_tmux_session_if_needed() {
    # Fetch the list of tmux sessions
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

    # If no sessions exist, create a new one
    if [[ -z "$sessions" ]]; then
        tmux new-session
        return
    fi

    # Option to create a new session
    local new_session_option="Create New Session"

    # Use fzf-tmux to select a session or create a new one
    local session=$(echo "$sessions"$'\n'"$new_session_option" | fzf-tmux --prompt="Select a session: " --header="Ctrl-N to create a new session" --bind="ctrl-n:execute-silent(tmux new-session \; detach-client)")

    # Create a new session if selected, otherwise attach to the chosen session
    if [[ "$session" == "$new_session_option" || -z "$session" ]]; then
        tmux new-session
    else
        tmux attach-session -t "$session"
    fi
}

# Only run the function in an interactive shell that is not already inside a tmux session
if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then
    attach_tmux_session_if_needed
fi
