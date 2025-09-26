#!/usr/bin/env zsh

# =============================================================================
# Modern Package Installation System
# Cross-platform package management with intelligent detection
# =============================================================================

# Colors for output
readonly PKG_RED='\033[0;31m'
readonly PKG_GREEN='\033[0;32m'
readonly PKG_YELLOW='\033[1;33m'
readonly PKG_BLUE='\033[0;34m'
readonly PKG_NC='\033[0m'

# Logging Functions
pkg_log_info()    { echo -e "${PKG_BLUE}[PKG INFO]${PKG_NC} $1" }
pkg_log_warning() { echo -e "${PKG_YELLOW}[PKG WARN]${PKG_NC} $1" }
pkg_log_error()   { echo -e "${PKG_RED}[PKG ERROR]${PKG_NC} $1" }
pkg_log_success() { echo -e "${PKG_GREEN}[PKG SUCCESS]${PKG_NC} $1" }

# =============================================================================
# System Detection
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                case "$ID" in
                    ubuntu|debian) echo "ubuntu" ;;
                    fedora|centos|rhel) echo "fedora" ;;
                    arch|manjaro) echo "arch" ;;
                    *) echo "linux" ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

get_package_manager() {
    local os="$1"
    case "$os" in
        macos)   command -v brew >/dev/null 2>&1 && echo "brew" || echo "none" ;;
        ubuntu)  command -v apt >/dev/null 2>&1 && echo "apt" || echo "none" ;;
        fedora)  
            command -v dnf >/dev/null 2>&1 && echo "dnf" || \
            command -v yum >/dev/null 2>&1 && echo "yum" || echo "none"
            ;;
        arch)    command -v pacman >/dev/null 2>&1 && echo "pacman" || echo "none" ;;
        *)       echo "none" ;;
    esac
}

# =============================================================================
# Package Management
# =============================================================================

is_command_available() {
    command -v "$1" >/dev/null 2>&1
}

install_with_package_manager() {
    local package="$1"
    local os=$(detect_os)
    local pm=$(get_package_manager "$os")
    
    case "$pm" in
        brew)   brew install "$package" ;;
        apt)    sudo apt install -y "$package" ;;
        dnf)    sudo dnf install -y "$package" ;;
        yum)    sudo yum install -y "$package" ;;
        pacman) sudo pacman -S --noconfirm "$package" ;;
        *)      
            pkg_log_error "No supported package manager found for $os"
            return 1
            ;;
    esac
}

# =============================================================================
# Specific Tool Installation
# =============================================================================

install_rust_tools() {
    local tools=("bat" "eza" "fd-find" "ripgrep" "zoxide")
    
    for tool in "${tools[@]}"; do
        local cmd="$tool"
        # Handle special cases where command name differs from package name
        case "$tool" in
            "fd-find") cmd="fd" ;;
            "ripgrep") cmd="rg" ;;
        esac
        
        if ! is_command_available "$cmd"; then
            pkg_log_info "Installing $tool..."
            
            # Try cargo first (usually more up-to-date)
            if is_command_available cargo; then
                cargo install "$tool" 2>/dev/null || install_with_package_manager "$tool"
            else
                install_with_package_manager "$tool"
            fi
            
            if is_command_available "$cmd"; then
                pkg_log_success "$tool installed successfully"
            else
                pkg_log_warning "Failed to install $tool"
            fi
        else
            pkg_log_info "$tool already installed"
        fi
    done
}

install_node_tools() {
    if ! is_command_available node; then
        pkg_log_info "Node.js not found, installing via package manager..."
        install_with_package_manager "nodejs npm"
    fi
    
    if is_command_available npm; then
        local tools=("tldr")
        for tool in "${tools[@]}"; do
            if ! is_command_available "$tool"; then
                pkg_log_info "Installing $tool via npm..."
                npm install -g "$tool" 2>/dev/null
            fi
        done
    fi
}

install_fzf() {
    if ! is_command_available fzf; then
        pkg_log_info "Installing fzf..."
        
        if [[ -d "$HOME/.fzf" ]]; then
            pkg_log_info "fzf directory exists, updating..."
            cd "$HOME/.fzf" && git pull
        else
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        fi
        
        "$HOME/.fzf/install" --all --no-bash --no-fish 2>/dev/null
        
        if is_command_available fzf; then
            pkg_log_success "fzf installed successfully"
        else
            pkg_log_warning "Failed to install fzf"
        fi
    else
        pkg_log_info "fzf already installed"
    fi
}

# =============================================================================
# Main Installation Function
# =============================================================================

install_modern_tools() {
    pkg_log_info "Installing modern command-line tools..."
    
    # Essential tools that should be available
    install_rust_tools
    install_fzf
    install_node_tools
    
    pkg_log_success "Modern tools installation completed"
}

# Auto-install if script is sourced and not already done
if [[ -z "$DOTFILES_TOOLS_INSTALLED" ]]; then
    export DOTFILES_TOOLS_INSTALLED=1
    install_modern_tools
fi