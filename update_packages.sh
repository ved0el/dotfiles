#!/usr/bin/env zsh

# =============================================================================
# Batch Update Package Scripts
# =============================================================================
# This script updates all package scripts to work with the new configuration system

echo "🔄 Updating package scripts to new configuration system..."

# Function to update a package script
update_package_script() {
  local script_file="$1"
  local package_name=$(basename "$script_file" .zsh)
  
  echo "  Updating $package_name..."
  
  # Update the script with new structure
  cat > "$script_file" << 'EOF'
#!/usr/bin/env zsh

# =============================================================================
# PACKAGE_NAME - PACKAGE_DESC
# =============================================================================

# Package information
PACKAGE_NAME="PACKAGE_NAME"
PACKAGE_DESC="PACKAGE_DESC"
PACKAGE_DEPS=""  # Dependencies, e.g., "git curl" or "" for none

# Pre-installation setup (optional)
pre_install() {
  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_info "Preparing PACKAGE_NAME installation..."
  fi
  return 0
}

# Post-installation setup (optional)
post_install() {
  if ! is_package_installed "$PACKAGE_NAME"; then
    log_error "$PACKAGE_NAME is not executable after installation"
    return 1
  fi

  if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
    log_success "$PACKAGE_NAME installed and ready"
  fi
  return 0
}

# Package initialization (REQUIRED - always runs)
# This function runs EVERY TIME the shell loads, regardless of installation status
init() {
  # Only run if package is available (either installed or already present)
  if is_package_installed "$PACKAGE_NAME"; then
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_info "Initializing PACKAGE_NAME"
    fi
    
    # Add your initialization logic here:
    # - Environment variables
    # - Aliases
    # - Completions
    # - PATH updates
    
    return 0
  else
    if [[ "${DOTFILES_VERBOSE:-false}" == "true" ]]; then
      log_warning "PACKAGE_NAME not available, skipping initialization"
    fi
    return 1
  fi
}

# =============================================================================
# Main Installation Flow (DO NOT MODIFY BELOW THIS LINE)
# =============================================================================

# Install package using simple package installation
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
EOF

  # Replace placeholders with actual package info
  sed -i.bak "s/PACKAGE_NAME/$package_name/g" "$script_file"
  sed -i.bak "s/PACKAGE_DESC/Description for $package_name/g" "$script_file"
  
  # Remove backup file
  rm -f "${script_file}.bak"
  
  echo "    ✅ $package_name updated"
}

# Get all package scripts (excluding template and already updated ones)
local package_scripts=($(find zshrc.d/packages -name "*.zsh" -not -name "00_template.zsh" -not -name "200_s_bat.zsh" -not -name "100_m_sheldon.zsh" -not -name "201_s_fzf.zsh" -not -name "202_s_eza.zsh" -not -name "206_s_zoxide.zsh" -not -name "300_d_nvm.zsh" -not -name "101_m_tmux.zsh"))

# Update each script
for script in "${package_scripts[@]}"; do
  update_package_script "$script"
done

echo "🎉 All package scripts updated successfully!"
echo "💡 Remember to customize each script with proper package information and initialization logic"
