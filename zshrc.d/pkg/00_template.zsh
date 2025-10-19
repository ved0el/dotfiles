#!/usr/bin/env zsh

# =============================================================================
# Package Template - Copy this file and modify for your package
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

# -----------------------------------------------------------------------------
# 1. Package Basic Info
# -----------------------------------------------------------------------------
PACKAGE_NAME="package_name"
PACKAGE_DESC="Package description"
PACKAGE_DEPS=""  # List dependencies if any

# -----------------------------------------------------------------------------
# 2. Pre-installation Configuration
# -----------------------------------------------------------------------------
pre_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Preparing $PACKAGE_NAME installation..."
  # Add any pre-installation setup here
  return 0
}

# -----------------------------------------------------------------------------
# 3. Post-installation Configuration
# -----------------------------------------------------------------------------
post_install() {
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Setting up $PACKAGE_NAME configuration..."
  # Add any post-installation setup here
  return 0
}

# -----------------------------------------------------------------------------
# 4. Initialization Configuration (runs every shell startup)
# -----------------------------------------------------------------------------
init() {
  # Only run if package is available
  if ! is_package_installed "$PACKAGE_NAME"; then
    return 1
  fi
  
  [[ "$DOTFILES_VERBOSE" == "true" ]] && echo "Initializing $PACKAGE_NAME"
  
  # Add initialization code here (aliases, environment variables, etc.)
  # Example:
  # alias example="$PACKAGE_NAME"
  # export EXAMPLE_VAR="value"
  
  return 0
}

# -----------------------------------------------------------------------------
# 5. Custom Installation (optional - only if standard installation doesn't work)
# -----------------------------------------------------------------------------
# Uncomment and modify if you need custom installation logic
# custom_install() {
#   local success=false
#   
#   # Add custom installation commands here
#   # Example: curl -L https://example.com/install.sh | bash
#   
#   return $([ "$success" == "true" ] && echo 0 || echo 1)
# }

# -----------------------------------------------------------------------------
# 6. Main Package Initialization
# -----------------------------------------------------------------------------
init_package_template "$PACKAGE_NAME" "$PACKAGE_DESC"