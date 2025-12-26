#!/usr/bin/env zsh

# NVM Lazy Loading with Auto-install LTS
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

lazy_load_nvm() {
    # Validate NVM_DIR exists
    if [[ ! -d "${NVM_DIR}" ]]; then
        echo "ERROR: NVM_DIR not found: ${NVM_DIR}" >&2
        return 1
    fi

    # Load nvm
    if [[ -f "${NVM_DIR}/nvm.sh" ]]; then
        source "${NVM_DIR}/nvm.sh" || {
            echo "ERROR: Failed to source nvm.sh" >&2
            return 1
        }
    else
        echo "ERROR: nvm.sh not found in ${NVM_DIR}" >&2
        return 1
    fi

    # Load bash completion if available (optional)
    [[ -f "${NVM_DIR}/bash_completion" ]] && source "${NVM_DIR}/bash_completion" 2>/dev/null

    # Verify nvm function was created
    if ! typeset -f nvm >/dev/null; then
        echo "ERROR: nvm function not available after loading" >&2
        return 1
    fi

    # Auto-install and use latest LTS if no Node version is installed
    _nvm_auto_install_lts

    return 0
}

# Auto-install latest LTS version if needed
_nvm_auto_install_lts() {
    # Check if any Node version is installed
    local installed_versions=$(nvm list 2>/dev/null | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    if [[ -z "$installed_versions" ]]; then
        echo "No Node.js version found. Installing latest LTS version..."

        # Install latest LTS version
        if nvm install --lts; then
            echo "✓ Latest LTS version installed successfully"

            # Set as default
            if nvm alias default 'lts/*'; then
                echo "✓ Latest LTS set as default"
            else
                echo "Warning: Failed to set LTS as default" >&2
            fi

            # Use the LTS version immediately
            nvm use --lts

            echo "✓ Node.js $(node --version) is now active"
        else
            echo "ERROR: Failed to install latest LTS version" >&2
            return 1
        fi
    else
        # Node is already installed, use default or LTS
        if nvm list default &>/dev/null | grep -q "default"; then
            # Use the default version
            nvm use default &>/dev/null
        else
            # No default set, use LTS if available, otherwise use latest installed
            if nvm list lts/* &>/dev/null | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+'; then
                nvm use --lts &>/dev/null
            else
                # Use any installed version
                nvm use node &>/dev/null
            fi
        fi
    fi
}

# Only create lazy wrappers if nvm is installed
if [[ -d "${NVM_DIR}" ]]; then
    # Verify lazy_load_wrapper.zsh exists and source it
    if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" ]]; then
        source "$DOTFILES_ROOT/zshrc.d/lib/lazy_load_wrapper.zsh" || {
            echo "ERROR: Failed to load lazy_load_wrapper.zsh" >&2
            return 1
        }

        # Verify create_lazy_wrapper function exists
        if typeset -f create_lazy_wrapper >/dev/null; then
            create_lazy_wrapper "nvm" "lazy_load_nvm" "node" "npm" "npx" "yarn"
        else
            echo "ERROR: create_lazy_wrapper function not found" >&2
        fi
    fi
fi
