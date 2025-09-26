#!/usr/bin/env bash

# =============================================================================
# Dotfiles Test Script
# Quick verification that the dotfiles system is working correctly
# =============================================================================

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

test_log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO)  echo -e "${BLUE}[TEST INFO]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[TEST WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[TEST ERROR]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[TEST SUCCESS]${NC} $message" ;;
    esac
}

test_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        test_log SUCCESS "$description: $cmd found"
        return 0
    else
        test_log WARN "$description: $cmd not found"
        return 1
    fi
}

test_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        test_log SUCCESS "$description: $file exists"
        return 0
    else
        test_log WARN "$description: $file missing"
        return 1
    fi
}

test_symlink() {
    local link="$1"
    local description="$2"
    
    if [[ -L "$link" ]]; then
        local target=$(readlink "$link")
        test_log SUCCESS "$description: $link -> $target"
        return 0
    else
        test_log WARN "$description: $link not a symlink"
        return 1
    fi
}

main() {
    echo "🧪 Testing Dotfiles Installation"
    echo "================================="
    echo
    
    local tests_passed=0
    local tests_total=0
    
    # Test essential commands
    test_log INFO "Testing essential commands..."
    for cmd in git zsh curl; do
        if test_command "$cmd" "Essential command"; then
            ((tests_passed++))
        fi
        ((tests_total++))
    done
    echo
    
    # Test modern tools (optional)
    test_log INFO "Testing modern tools..."
    for cmd in bat eza fd rg zoxide fzf sheldon; do
        if test_command "$cmd" "Modern tool"; then
            ((tests_passed++))
        fi
        ((tests_total++))
    done
    echo
    
    # Test configuration files
    test_log INFO "Testing configuration files..."
    local configs=(
        "$HOME/.zshrc:ZSH configuration"
        "$HOME/.gitconfig:Git configuration"
        "$HOME/.gitignore_global:Global gitignore"
    )
    
    for config in "${configs[@]}"; do
        local file="${config%:*}"
        local desc="${config#*:}"
        if test_symlink "$file" "$desc"; then
            ((tests_passed++))
        fi
        ((tests_total++))
    done
    echo
    
    # Test tmux if not in SSH/IDE
    if [[ -z "${SSH_CONNECTION:-}" && "${TERM_PROGRAM:-}" != "vscode" ]]; then
        test_log INFO "Testing tmux (not in SSH/IDE)..."
        if test_command "tmux" "Tmux"; then
            ((tests_passed++))
        fi
        if test_symlink "$HOME/.tmux.conf" "Tmux configuration"; then
            ((tests_passed++))
        fi
        ((tests_total+=2))
    else
        test_log INFO "Skipping tmux tests (SSH/IDE environment detected)"
    fi
    echo
    
    # Test Sheldon configuration
    test_log INFO "Testing Sheldon configuration..."
    local sheldon_config="$HOME/.dotfiles/config/sheldon/plugins.toml"
    if test_file "$sheldon_config" "Sheldon config"; then
        ((tests_passed++))
    fi
    ((tests_total++))
    echo
    
    # Summary
    echo "📊 Test Results"
    echo "==============="
    echo "Tests passed: $tests_passed/$tests_total"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        test_log SUCCESS "All tests passed! 🎉"
        echo
        test_log INFO "Your dotfiles are properly configured!"
        test_log INFO "Restart your terminal or run 'exec zsh' to use the new configuration."
        return 0
    else
        local failed=$((tests_total - tests_passed))
        test_log WARN "$failed tests failed"
        echo
        test_log INFO "Some tools might not be installed yet."
        test_log INFO "Run './install.sh' to install missing components."
        return 1
    fi
}

main "$@"