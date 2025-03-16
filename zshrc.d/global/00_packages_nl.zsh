#!/usr/bin/env zsh

# List of packages to check and install
# Define the array of cmd - package pairs
cmds=(
  "sheldon"
  "fd"
  "rg"
  "bat"
  "fzf"
  "eza"
  # "nvm"
)

# Check and install packages if not installed
check_and_install_packages() {
  for cmd in "${cmds[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "\033[1;36m$cmd\033[m not found."
      custom_install_script="$ZSHRC_CONFIG_DIR/scripts/install_$cmd.zsh"
      if [[ -f "$custom_install_script" ]]; then
        source "$custom_install_script"
      else
        echo "No custom install script found for \033[1;36m$cmd\033[m."
        continue
      fi
    else
      # echo "\033[1;36m$cmd\033[m was installed. Skipping..."
    fi
  done
}

# Call the function
check_and_install_packages
