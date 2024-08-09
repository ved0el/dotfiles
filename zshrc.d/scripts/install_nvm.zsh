#!/usr/bin/env zsh

# nvm - Node Version Manager
# https://github.com/nvm-sh/nvm

# Display message in cyan
print_message() {
  echo -e "Installing \033[1;36m$1\033[m via $2..."
}

# Display warning message in yellow
print_warning() {
  echo -e "\033[1;33mWarning:\033[m $1 update failed."
}

# Display error message in red
print_error() {
  echo -e "\033[1;31mError:\033[m Failed to install \033[1;36m$1\033[m via $2."
}

# Check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Installing NVM
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"

print_message "nvm" "curl"

# Download and install nvm
if curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash; then
  # Load nvm
  source "$NVM_DIR/nvm.sh"

  # Verify installation
  if command_exists nvm; then
    echo -e "\033[1;32mnvm successfully installed!\033[m"
  else
    print_error "nvm" "curl"
    exit 1
  fi
else
  print_error "nvm" "curl"
  exit 1
fi
