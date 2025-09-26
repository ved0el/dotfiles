# If under a login shell, source /etc/zshrc if present
[[ -r /etc/zshrc ]] && source /etc/zshrc

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Prompt (simple)
PROMPT='%F{cyan}%n%f@%F{yellow}%m%f:%F{green}%~%f$ '

# Paths
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Sheldon plugin manager
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

# Aliases
alias ll='ls -alF'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

