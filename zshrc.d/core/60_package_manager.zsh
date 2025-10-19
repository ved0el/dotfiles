#!/usr/bin/env zsh

# Package management system - Profile-based package loading

# Load package management library
if [[ -f "$DOTFILES_ROOT/zshrc.d/lib/install_helper.zsh" ]]; then
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "✅ Loading package install helper"
    source "$DOTFILES_ROOT/zshrc.d/lib/install_helper.zsh"
else
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "❌ Package install helper not found"
fi

# Function to load packages based on profile (hierarchical loading)
load_packages_by_profile() {
    local profile="${DOTFILES_PROFILE:-minimal}"
    local pkg_dir="$DOTFILES_ROOT/zshrc.d/pkg"
    local patterns=()
    
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "📦 Loading packages for profile: $profile"
    
    # Determine file patterns based on profile (hierarchical)
    case "$profile" in
        minimal)
            patterns=("*_m_*.zsh")
            ;;
        server)
            patterns=("*_m_*.zsh" "*_s_*.zsh")
            ;;
        develop)
            patterns=("*_m_*.zsh" "*_s_*.zsh" "*_d_*.zsh")
            ;;
        *)
            [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "⚠️  Unknown profile '$profile', defaulting to minimal"
            patterns=("*_m_*.zsh")
            ;;
    esac
    
    # Check if pkg directory exists
    if [[ ! -d "$pkg_dir" ]]; then
        [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "⚠️  Package directory not found: $pkg_dir"
        return 1
    fi
    
    # Collect all matching files from all patterns
    local all_files=()
    for pattern in "${patterns[@]}"; do
        local files=($pkg_dir/$~pattern)
        all_files+=("${files[@]}")
    done
    
    if [[ ${#all_files} -eq 0 ]]; then
        [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "⚠️  No package files found for patterns: ${patterns[*]}"
        return 1
    fi
    
    # Sort files to ensure correct loading order
    all_files=("${(@n)all_files}")
    
    # Source each matching file
    for file in "${all_files[@]}"; do
        local basename=$(basename "$file")
        
        # Skip template files
        if [[ "$basename" == *_template.zsh ]]; then
            continue
        fi
        
        if [[ -f "$file" ]]; then
            [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "  ✅ Loading $basename"
            source "$file"
        fi
    done
    
    [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "✅ Package loading complete for profile: $profile (${#all_files[@]} packages)"
    return 0
}

# Load packages based on DOTFILES_PROFILE
load_packages_by_profile
