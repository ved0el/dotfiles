#!/usr/bin/env zsh

# =============================================================================
# Lazy Loading System - Load packages only when needed
# =============================================================================

# Function to create lazy loading wrapper
create_lazy_wrapper() {
    local command_name="$1"
    local init_function="$2"
    local loaded=false
    
    # Create a function that loads the real command on first use
    eval "${command_name}() {
        if [[ \"\$loaded\" == \"false\" ]]; then
            loaded=true
            $init_function
        fi
        command $command_name \"\$@\"
    }"
}

# Lazy load NVM
lazy_load_nvm() {
    local nvm_dir="${HOME}/.nvm"
    if [[ -d "$nvm_dir" ]]; then
        if [[ -f "$nvm_dir/nvm.sh" ]]; then
            source "$nvm_dir/nvm.sh"
        fi
        if [[ -f "$nvm_dir/bash_completion" ]]; then
            source "$nvm_dir/bash_completion"
        fi
    fi
}

# Lazy load Pyenv
lazy_load_pyenv() {
    local pyenv_dir="${HOME}/.pyenv"
    if [[ -d "$pyenv_dir" ]]; then
        export PATH="$pyenv_dir/bin:$PATH"
        if command -v pyenv &>/dev/null; then
            eval "$(pyenv init -)"
        fi
    fi
}

# Lazy load Goenv
lazy_load_goenv() {
    local goenv_dir="${HOME}/.goenv"
    if [[ -d "$goenv_dir" ]]; then
        export PATH="$goenv_dir/bin:$PATH"
        if command -v goenv &>/dev/null; then
            eval "$(goenv init -)"
        fi
    fi
}

# Lazy load Sheldon
lazy_load_sheldon() {
    local sheldon_config_dir="${HOME}/.config/sheldon"
    local sheldon_config_file="${sheldon_config_dir}/plugins.toml"
    
    if [[ -d "$sheldon_config_dir" && -f "$sheldon_config_file" ]]; then
        eval "$(sheldon source)" &>/dev/null
    fi
}
