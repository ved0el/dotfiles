# /usr/bin/zsh

# sheldon - fast, configurable, shell plugin manager
# https://github.com/rossmacarthur/sheldon

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
  print_message "sheldon" "Homebrew"
  brew update &>/dev/null || print_warning "Homebrew"
  brew install sheldon
  if [ $? -ne 0 ]; then
    print_error "sheldon" "Homebrew"
    exit 1
  fi

# Linux
elif [[ $OSTYPE == "Linux" ]]; then
  print_message "sheldon" "curl"
  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
  | bash -s -- --repo rossmacarthur/sheldon --to $DOTFILES_DIR/bin
  if [ $? -ne 0 ]; then
    print_error "sheldon" "apt"
    exit 1
  fi
fi
