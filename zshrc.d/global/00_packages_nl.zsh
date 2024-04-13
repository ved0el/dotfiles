# List of packages to check and install
# Define the array of cmd - package pairs
cmd_package_pairs=(
  "sheldon - sheldon"
  "fd - fd"
  "rg - ripgrep"
  "bat - bat"
  "fzf - fzf"
  "exa - exa"
  "node - nvm"
)

# Iterate over cmd_package_pairs array


# Check and install packages if not installed
check_and_install_packages() {
  local SCRIPTS_DIR="$ZSHRC_CONFIG_DIR/scripts"

  for pair in "${cmd_package_pairs[@]}"; do
  # Split the pair into command and package
  IFS=' - ' read -r cmd package <<< "$pair"

  if ! command -v "$cmd" &> /dev/null; then
    echo "\033[1;36m$package\033[m not found. Installing..."
    custom_install_script="$SCRIPTS_DIR/install_$package.zsh"
    if [[ -f "$custom_install_script" ]]; then
      echo "Custom install script found for \033[1;36m$package\033[m. Installing using custom script..."
      source "$custom_install_script"
    else
      echo "No custom install script found for \033[1;36m$package\033[m. Checking system package manager..."
      if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "Detected macOS. Installing \033[1;36m$package\033[m via Homebrew..."
        brew update >/dev/null 2>&1 || echo "Warning: Homebrew update failed."
        brew install "$package"
        if [ $? -ne 0 ]; then
          echo "Error: Failed to install \033[1;36m$package\033[m via Homebrew."
          continue
        fi
      elif [[ "$(uname -s)" == "Linux" ]]; then
        echo "Detected Linux. Installing \033[1;36m$package\033[m via apt..."
        sudo apt update >/dev/null 2>&1 || echo "Warning: apt update failed."
        sudo apt install -y "$package"
        if [ $? -ne 0 ]; then
          echo "Error: Failed to install \033[1;36m$package\033[m via apt."
          continue
        fi
      else
        echo "Current architecture is not supported for \033[1;36m$package\033[m installation. Skipping..."
        continue
      fi
    fi
  else
    echo "\033[1;36m$package\033[m is already installed. Skipping..."
  fi
  done
}

# Call the function
check_and_install_packages
