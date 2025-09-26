#!/usr/bin/env bash

# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# A modern, cross-platform dotfiles management system
# Supports: Ubuntu, macOS with intelligent environment detection
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly DOTFILES_REPO="https://github.com/ved0el/dotfiles.git"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly LOG_FILE="/tmp/dotfiles-install.log"

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "${BLUE}[INFO]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_banner() {
    cat << 'EOF'
 ____        _    __ _ _           
|  _ \  ___ | |_ / _(_) | ___  ___ 
| | | |/ _ \| __| |_| | |/ _ \/ __|
| |_| | (_) | |_|  _| | |  __/\__ \
|____/ \___/ \__|_| |_|_|\___||___/
                                  
Modern Cross-Platform Configuration Management
EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_running_in_ssh() {
    [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]]
}

is_running_in_ide() {
    [[ "${TERM_PROGRAM:-}" == "vscode" || -n "${VSCODE_PID:-}" || -n "${CURSOR_PID:-}" ]]
}

should_install_tmux() {
    ! is_running_in_ssh && ! is_running_in_ide
}

# =============================================================================
# OS Detection and Package Management
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
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
        *)
            echo "unknown"
            ;;
    esac
}

get_package_manager() {
    local os="$1"
    case "$os" in
        macos)   echo "brew" ;;
        ubuntu)  echo "apt" ;;
        fedora)  echo "dnf" ;;
        arch)    echo "pacman" ;;
        *)       echo "unknown" ;;
    esac
}

# =============================================================================
# Package Installation
# =============================================================================

install_package_manager() {
    local os="$1"
    
    case "$os" in
        macos)
            if ! command_exists brew; then
                log INFO "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH for Apple Silicon Macs
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            else
                log INFO "Homebrew already installed"
            fi
            ;;
        ubuntu)
            log INFO "Updating package lists..."
            sudo apt update
            ;;
        *)
            log WARN "Package manager setup not implemented for OS: $os"
            ;;
    esac
}

install_essential_packages() {
    local os="$1"
    local pm="$2"
    
    local packages=(git zsh curl)
    if should_install_tmux; then
        packages+=(tmux)
    fi
    
    log INFO "Installing essential packages: ${packages[*]}"
    
    case "$pm" in
        brew)
            brew install "${packages[@]}"
            ;;
        apt)
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        *)
            log ERROR "Unsupported package manager: $pm"
            return 1
            ;;
    esac
}

install_sheldon() {
    if command_exists sheldon; then
        log INFO "Sheldon already installed"
        return 0
    fi
    
    log INFO "Installing Sheldon plugin manager..."
    
    if command_exists curl; then
        curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
            | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
        
        # Add ~/.local/bin to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
            export PATH="$HOME/.local/bin:$PATH"
        fi
    else
        log ERROR "curl is required to install Sheldon"
        return 1
    fi
}

# =============================================================================
# Dotfiles Management
# =============================================================================

clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log INFO "Dotfiles directory exists, updating..."
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log INFO "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

backup_existing_configs() {
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local configs=(
        ".zshrc"
        ".tmux.conf"
        ".gitconfig"
        ".p10k.zsh"
    )
    
    local needs_backup=false
    for config in "${configs[@]}"; do
        if [[ -f "$HOME/$config" && ! -L "$HOME/$config" ]]; then
            needs_backup=true
            break
        fi
    done
    
    if [[ "$needs_backup" == true ]]; then
        log INFO "Backing up existing configurations to $backup_dir"
        mkdir -p "$backup_dir"
        
        for config in "${configs[@]}"; do
            if [[ -f "$HOME/$config" && ! -L "$HOME/$config" ]]; then
                cp "$HOME/$config" "$backup_dir/"
                log INFO "Backed up $config"
            fi
        done
    fi
}

create_symlinks() {
    log INFO "Creating symbolic links..."
    
    local configs=(
        "zshrc:.zshrc"
        "tmux.conf:.tmux.conf"
        "gitconfig:.gitconfig"
        "gitignore_global:.gitignore_global"
        "p10k.zsh:.p10k.zsh"
    )
    
    for config in "${configs[@]}"; do
        local source="${config%:*}"
        local target="${config#*:}"
        local source_path="$DOTFILES_DIR/$source"
        local target_path="$HOME/$target"
        
        if [[ -f "$source_path" ]]; then
            # Remove existing file/link
            [[ -e "$target_path" ]] && rm -f "$target_path"
            
            ln -sf "$source_path" "$target_path"
            log INFO "Linked $source -> $target"
        else
            log WARN "Source file not found: $source_path"
        fi
    done
    
    # Create config directory symlink
    local config_dir="$HOME/.config"
    [[ ! -d "$config_dir" ]] && mkdir -p "$config_dir"
    
    if [[ -d "$DOTFILES_DIR/config" ]]; then
        [[ -L "$config_dir/dotfiles" ]] && rm -f "$config_dir/dotfiles"
        ln -sf "$DOTFILES_DIR/config" "$config_dir/dotfiles"
        log INFO "Linked config directory"
    fi
}

setup_git_config() {
    log INFO "Setting up Git configuration..."
    
    # Create a basic gitconfig if it doesn't exist
    if [[ ! -f "$DOTFILES_DIR/gitconfig" ]]; then
        cat > "$DOTFILES_DIR/gitconfig" << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com
    
[core]
    editor = vim
    autocrlf = input
    safecrlf = true
    
[init]
    defaultBranch = main
    
[pull]
    rebase = false
    
[push]
    default = simple
    
[alias]
    st = status
    co = checkout
    br = branch
    cm = commit
    lg = log --oneline --graph --decorate
EOF
        log INFO "Created basic Git configuration. Please update user details in ~/.gitconfig"
    fi
}

install_tmux_plugins() {
    if ! should_install_tmux; then
        log INFO "Skipping tmux plugin installation (SSH/IDE environment detected)"
        return 0
    fi
    
    if ! command_exists tmux; then
        log WARN "tmux not installed, skipping plugin installation"
        return 0
    fi
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        log INFO "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        
        # Install plugins
        "$tpm_dir/bin/install_plugins"
        log SUCCESS "TMux plugins installed"
    else
        log INFO "TPM already installed"
    fi
}

# =============================================================================
# Shell Setup
# =============================================================================

setup_zsh() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        log INFO "Setting zsh as default shell..."
        local zsh_path=$(which zsh)
        
        if command_exists chsh; then
            chsh -s "$zsh_path"
            log SUCCESS "Default shell changed to zsh"
        else
            log WARN "chsh not available. Please manually change your default shell to: $zsh_path"
        fi
    else
        log INFO "zsh is already the default shell"
    fi
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
    print_banner
    echo
    
    log INFO "Starting dotfiles installation..."
    log INFO "Log file: $LOG_FILE"
    
    # Detect system
    local os=$(detect_os)
    local pm=$(get_package_manager "$os")
    
    log INFO "Detected OS: $os"
    log INFO "Package manager: $pm"
    log INFO "SSH connection: $(is_running_in_ssh && echo 'Yes' || echo 'No')"
    log INFO "IDE environment: $(is_running_in_ide && echo 'Yes' || echo 'No')"
    log INFO "Will install tmux: $(should_install_tmux && echo 'Yes' || echo 'No')"
    
    echo
    read -p "Continue with installation? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log INFO "Installation cancelled"
        exit 0
    fi
    
    # Installation steps
    install_package_manager "$os"
    install_essential_packages "$os" "$pm"
    install_sheldon
    
    clone_dotfiles
    backup_existing_configs
    setup_git_config
    create_symlinks
    
    if should_install_tmux; then
        install_tmux_plugins
    fi
    
    setup_zsh
    
    log SUCCESS "Dotfiles installation completed!"
    echo
    log INFO "Next steps:"
    echo "  1. Update Git user information in ~/.gitconfig"
    echo "  2. Restart your terminal or run: exec zsh"
    echo "  3. Customize your configuration as needed"
    
    if should_install_tmux; then
        echo "  4. tmux plugins will be automatically installed on first tmux session"
    fi
    
    echo
    echo "Configuration directory: $DOTFILES_DIR"
    echo "Backup directory: $(ls -td ~/.dotfiles-backup-* 2>/dev/null | head -1 || echo 'No backup created')"
}

# Run main function
main "$@"