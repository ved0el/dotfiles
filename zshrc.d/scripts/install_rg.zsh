#!/usr/bin/env zsh

# rg - recursively search the current directory for lines matching a pattern
# https://github.com/BurntSushi/ripgrep

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

# Checking os type
local OSTYPE=$(uname -s)

# MacOS
if [[ $OSTYPE == "Darwin" ]]; then
  print_message "ripgrep" "Homebrew"
  brew update &>/dev/null || print_warning "Homebrew"
  brew install ripgrep
  if [ $? -ne 0 ]; then
    print_error "ripgrep" "Homebrew"
    exit 1
  fi

# Linux
elif [[ $OSTYPE == "Linux" ]]; then
  print_message "sheldon" "apt"
  sudo apt update &>/dev/null || print_warning "apt"
  sudo apt install -y ripgrep
  if [ $? -ne 0 ]; then
    print_error "ripgrep" "apt"
    exit 1
  fi
fi
