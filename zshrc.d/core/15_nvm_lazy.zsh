#!/usr/bin/env zsh

# =============================================================================
# NVM Lazy Loading - Working approach
# =============================================================================

# Set NVM_DIR but don't load NVM yet
export NVM_DIR="$HOME/.nvm"

# Simple function to load NVM when needed
load_nvm() {
    if [[ -f "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
    fi
    if [[ -f "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
    fi
}

# Create functions that load NVM on first use
nvm() {
    load_nvm
    # Use the actual nvm function that was loaded
    unfunction nvm
    nvm "$@"
}

node() {
    load_nvm
    command node "$@"
}

npm() {
    load_nvm
    command npm "$@"
}

npx() {
    load_nvm
    command npx "$@"
}

yarn() {
    load_nvm
    command yarn "$@"
}