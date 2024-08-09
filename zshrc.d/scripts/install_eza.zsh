#!/usr/bin/env zsh

# eza - modern, maintained replacement for ls
# https://github.com/eza-community/eza

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
  print_message "eza" "Homebrew"
  if brew update &>/dev/null; then
    brew install eza
    if ! command_exists eza; then
      print_error "eza" "Homebrew"
      exit 1
    fi
  else
    print_warning "Homebrew"
    exit 1
  fi

# Linux
elif [[ $OSTYPE == "Linux" ]]; then
  print_message "eza" "manual installation"
  VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
  curl -LO https://github.com/eza-community/eza/releases/download/${VERSION}/eza-${VERSION}-x86_64-unknown-linux-musl.tar.gz
  tar -xzf eza-${VERSION}-x86_64-unknown-linux-musl.tar.gz
  sudo mv eza /usr/local/bin/
  rm eza-${VERSION}-x86_64-unknown-linux-musl.tar.gz
  if ! command_exists eza; then
    print_error "eza" "manual installation"
    exit 1
  fi
else
  echo -e "\033[1;31mUnsupported OS type: $OSTYPE\033[m"
  exit 1
fi
