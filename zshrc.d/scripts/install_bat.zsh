#!/usr/bin/env zsh

# bat - a cat clone with wings
# https://github.com/sharkdp/bat

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

# Checking OS type
OSTYPE=$(uname -s)

# MacOS
if [[ $OSTYPE == "Darwin" ]]; then
  print_message "bat" "Homebrew"
  if brew update &>/dev/null; then
    brew install bat
    if ! command_exists bat; then
      print_error "bat" "Homebrew"
      exit 1
    fi
  else
    print_warning "Homebrew"
    exit 1
  fi

# Linux
elif [[ $OSTYPE == "Linux" ]]; then
  print_message "bat" "apt"
  if sudo apt update &>/dev/null; then
    sudo apt install -y bat || sudo apt install -y batcat
    if ! command_exists bat && ! command_exists batcat; then
      print_error "bat" "apt"
      exit 1
    fi

    # Creating symlink for batcat if installed as batcat
    if ! command_exists bat && command_exists batcat; then
      mkdir -p ~/.local/bin
      ln -sf $(which batcat) ~/.local/bin/bat
    fi
  else
    print_warning "apt"
    exit 1
  fi

else
  echo -e "\033[1;31mUnsupported OS type: $OSTYPE\033[m"
  exit 1
fi
