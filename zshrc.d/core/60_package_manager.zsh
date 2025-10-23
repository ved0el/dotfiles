#!/usr/bin/env zsh

# =============================================================================
# Ultra-Fast Package Manager - Production optimized
# =============================================================================

# Package manager optimized for fast loading

# Load package management library
if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/install_helper.zsh" ]]; then
    source "$DOTFILES_ROOT/zshrc.d/lib/install_helper.zsh"
fi

# Cache directory for package states
typeset -g __PKG_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/packages"
typeset -g __PKG_CACHE_FILE="${__PKG_CACHE_DIR}/package_states"

# Function to initialize cache directory
init_package_cache() {
    if [[ ! -d "$__PKG_CACHE_DIR" ]]; then
        mkdir -p "$__PKG_CACHE_DIR" 2>/dev/null
    fi
}

# Function to check if package is installed (cached)
is_package_installed_cached() {
    local package_name="$1"
    local cache_file="$__PKG_CACHE_FILE"
    
    # Check cache first (if less than 1 hour old)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt 3600 ]]; then
            if grep -q "^${package_name}:installed$" "$cache_file" 2>/dev/null; then
                return 0
            elif grep -q "^${package_name}:missing$" "$cache_file" 2>/dev/null; then
                return 1
            fi
        fi
    fi
    
    # Cache miss or expired - check actual installation
    local is_installed=false
    if command -v "$package_name" &>/dev/null; then
        is_installed=true
    fi
    
    # Update cache
    init_package_cache
    if [[ "$is_installed" == "true" ]]; then
        echo "${package_name}:installed" >> "$cache_file"
    else
        echo "${package_name}:missing" >> "$cache_file"
    fi
    
    # Return result
    [[ "$is_installed" == "true" ]] && return 0 || return 1
}

# Ultra-fast package loading function
load_packages_lazy() {
    local profile="${DOTFILES_PROFILE:-minimal}"
    local pkg_dir="$DOTFILES_ROOT/zshrc.d/pkg"
    
    # Pre-populate cache for all packages to avoid individual command -v calls
    local cache_file="$__PKG_CACHE_FILE"
    if [[ ! -f "$cache_file" ]] || [[ $(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0))) -gt 3600 ]]; then
        init_package_cache
        # Check all common packages at once
        local packages=("sheldon" "bat" "fzf" "eza" "fd" "rg" "tldr" "zoxide" "nvm" "pyenv" "goenv" "curlie")
        for pkg in "${packages[@]}"; do
            if command -v "$pkg" &>/dev/null; then
                echo "${pkg}:installed" >> "$cache_file"
            else
                echo "${pkg}:missing" >> "$cache_file"
            fi
        done
    fi
    
    # Pre-define patterns for speed
    local patterns=()
    case "$profile" in
        minimal) patterns=("*_m_*.zsh") ;;
        server) patterns=("*_m_*.zsh" "*_s_*.zsh") ;;
        develop) patterns=("*_m_*.zsh" "*_s_*.zsh" "*_d_*.zsh") ;;
        *) patterns=("*_m_*.zsh") ;;
    esac
    
    # Fast file collection and loading
    local files=()
    local loaded=0
    
    # Collect files safely (avoid "no matches found" error)
    for pattern in "${patterns[@]}"; do
        local matches=($pkg_dir/$~pattern(N))
        files+=($matches)
    done
    
    # Sort and load files
    for file in "${(@n)files}"; do
        [[ "$file" == *template* ]] && continue
        if [[ -f "$file" ]]; then
            source "$file" && ((loaded++))
        fi
    done
    
    return 0
}

# Initialize cache and load packages
init_package_cache
load_packages_lazy
