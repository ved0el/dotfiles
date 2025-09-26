#!/usr/bin/env zsh

# =============================================================================
# Package Template - Standardized Structure
# =============================================================================
# Copy this template to create new package files
# Rename: 00_template.zsh -> XX_[m|s|d]_package_name.zsh
# Where XX is priority (100, 200, 300...), [m|s|d] is profile type

# -----------------------------------------------------------------------------
# Package Configuration (REQUIRED)
# -----------------------------------------------------------------------------
PACKAGE_NAME="package_name"           # Command name to check installation
PACKAGE_DESC="Package description"    # Human-readable description
PACKAGE_DEPS=""                       # Space-separated dependencies
PACKAGE_TYPE="standard"               # standard|custom|script

# -----------------------------------------------------------------------------
# Installation Functions (OPTIONAL)
# -----------------------------------------------------------------------------

# Pre-installation setup
pre_install() {
  log_debug "Preparing $PACKAGE_NAME installation..."
  # Add any pre-installation logic here
  return 0
}

# Post-installation setup
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME installation verification failed"
    return 1
  fi
  
  log_debug "Setting up $PACKAGE_NAME configuration..."
  # Add any post-installation logic here
  return 0
}

# Package initialization (REQUIRED - runs on every shell load)
init() {
  if is_package_installed "$PACKAGE_NAME"; then
    log_debug "Initializing $PACKAGE_NAME..."
    # Add environment setup, aliases, functions here
    # This runs EVERY TIME the shell loads
    return 0
  else
    log_debug "$PACKAGE_NAME not available, skipping initialization"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Installation Logic (AUTOMATIC)
# -----------------------------------------------------------------------------
# The installer will automatically handle installation based on PACKAGE_TYPE

# For standard packages (most common):
# - Uses system package manager
# - No additional code needed

# For custom packages (special installation):
# - Override install_custom() function
# - Example: install_custom() { curl -sSL https://install.sh | bash }

# For script packages (download and run):
# - Override install_script() function  
# - Example: install_script() { curl -o- https://script.sh | bash }

# -----------------------------------------------------------------------------
# Custom Installation Functions (OPTIONAL)
# -----------------------------------------------------------------------------

# Custom installation logic (override for special cases)
# install_custom() {
#   log_info "Installing $PACKAGE_NAME using custom method..."
#   # Add custom installation logic here
#   return 0
# }

# Script-based installation (for tools that provide install scripts)
# install_script() {
#   log_info "Installing $PACKAGE_NAME using install script..."
#   # Add script installation logic here
#   return 0
# }

# -----------------------------------------------------------------------------
# Automatic Installation Flow (DO NOT MODIFY)
# -----------------------------------------------------------------------------
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install || return 1
  
  case "$PACKAGE_TYPE" in
    custom)
      if typeset -f install_custom >/dev/null; then
        install_custom && post_install
      else
        log_error "Custom installation function not defined for $PACKAGE_NAME"
        return 1
      fi
      ;;
    script)
      if typeset -f install_script >/dev/null; then
        install_script && post_install
      else
        log_error "Script installation function not defined for $PACKAGE_NAME"
        return 1
      fi
      ;;
    standard|*)
      install_package "$PACKAGE_NAME" "$PACKAGE_DESC" && post_install
      ;;
  esac
fi