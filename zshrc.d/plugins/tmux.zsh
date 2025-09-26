#!/usr/bin/env zsh

# =============================================================================
# Tmux Auto-Attach Configuration
# Automatically manage tmux sessions for improved workflow
# =============================================================================

# Skip if tmux is not installed
if ! command -v tmux >/dev/null 2>&1; then
    return 0
fi

# Function to intelligently attach or create tmux sessions
attach_tmux_session_if_needed() {
    # Check if tmux server is running and has sessions
    if tmux list-sessions >/dev/null 2>&1; then
        # Get the first available session
        local session_name=$(tmux list-sessions -F '#{session_name}' | head -n1)
        echo "Attaching to existing tmux session: $session_name"
        tmux attach-session -t "$session_name"
    else
        # Create a new session with a meaningful name
        local session_name="main-$(date +%H%M)"
        echo "Creating new tmux session: $session_name"
        tmux new-session -s "$session_name"
    fi
}

# Auto-attach conditions:
# - Interactive shell
# - Not already in tmux
# - Not in SSH connection
# - Not in IDE environment
# - Has a TTY
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -z "${SSH_CONNECTION:-}" ]] && [[ "${TERM_PROGRAM:-}" != "vscode" ]] && [[ -t 1 ]]; then
    attach_tmux_session_if_needed
fi
