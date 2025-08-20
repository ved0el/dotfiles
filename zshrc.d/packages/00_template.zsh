#!/usr/bin/env zsh

# =============================================================================
# Package Template - Copy this file and modify for new packages
# =============================================================================
#
# NAMING CONVENTION:
#   100_m_package.zsh  - minimal profile (shell tools)
#   200_s_package.zsh  - server profile (minimal + utilities)
#   300_d_package.zsh  - develop profile (minimal + utilities + dev tools)
#
# EXAMPLES:
#   100_m_sheldon.zsh    - sheldon for minimal profile
#   200_s_bat.zsh        - bat for server profile
#   300_d_goenv.zsh      - goenv for develop profile
#
# NUMBERING RANGES:
#   Minimal: 100-199 (shell essentials) - 99 slots
#   Server:  200-299 (utilities) - 99 slots
#   Develop: 300-399 (development tools) - 99 slots
#   Future:  400+ (extensions)
#
# DEPENDENCIES:
#   - List required packages that must be installed first
#   - Use empty string "" if no dependencies
#   - Multiple dependencies: "package1 package2"
#
# PLATFORM SUPPORT:
#   - macos: Homebrew
#   - linux: apt, dnf, yum, pacman, zypper
#   - freebsd: pkg
#   - custom: Manual installation commands
# =============================================================================

# Package information
PACKAGE_NAME="package_name"
PACKAGE_DESC="Description of what this package does"
PACKAGE_DEPS=""  # Dependencies, e.g., "git curl" or "" for none

# Pre-installation setup (optional)
pre_install() {
  # Add any setup that needs to happen before installation
  # Examples: create directories, download files, etc.
  return 0
}

# Post-installation setup (optional)
post_install() {
  # Add any setup that needs to happen after installation
  # Examples: configuration, symlinks, etc.
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  log_success "$PACKAGE_NAME installed and ready"
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
# Use this for: environment variables, aliases, completions, PATH updates, etc.
init() {
  # IMPORTANT: This function always runs, even if the package is already installed
  # Use this for setting up the environment, not for installation logic
  
  # Examples of what to put in init():
  # - export PATH="$PATH:/path/to/package/bin"
  # - alias package="package_command"
  # - source completions
  # - set environment variables
  
  # Only run if package is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    # Package is available - set up environment
    # export PATH="$PATH:/path/to/package/bin"
    # alias package="package_command"
    return 0
  else
    # Package not available - skip environment setup
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================
#
# The package installer now automatically:
# 1. Sources this script
# 2. Runs the init() function (for environment setup)
# 3. Handles installation if needed
#
# You only need to define the functions above - the installer handles the rest!

# =============================================================================
# SIMPLE INSTALLATION (recommended for most packages)
# =============================================================================

# For standard packages that follow normal naming conventions:
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi

# =============================================================================
# CUSTOM INSTALLATION (for special cases)
# =============================================================================

# For packages that need special handling (custom binary names, special installers):
#
# if ! is_package_installed "$PACKAGE_NAME"; then
#   log_info "Installing $PACKAGE_NAME..."
#
#   local pm=$(get_package_manager)
#   local success=false
#
#   case "$pm" in
#     brew)
#       if brew install package_name; then
#         success=true
#       fi
#       ;;
#     apt)
#       if sudo apt update && sudo apt install -y package_name; then
#         success=true
#       fi
#       ;;
#     dnf)
#       if sudo dnf install -y package_name; then
#         success=true
#       fi
#       ;;
#     custom)
#       # Custom installation commands here
#       if curl -L https://example.com/install.sh | bash; then
#         success=true
#       fi
#       ;;
#   esac
#
#   if [[ "$success" == "true" ]]; then
#     success=true
#     post_install
#   else
#     log_error "Failed to install $PACKAGE_NAME"
#   fi
# fi

# =============================================================================
# IMPORTANT NOTES
# =============================================================================
#
# 1. The init() function ALWAYS runs when the shell loads
# 2. Installation only happens if the package is not present
# 3. Environment setup happens regardless of installation status
# 4. Use init() for environment variables, aliases, completions
# 5. Use pre_install/post_install for installation-specific setup
#
# This ensures that your shell environment is always properly configured,
# whether the package was just installed or was already present!
