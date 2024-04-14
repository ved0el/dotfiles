
#!/usr/bin/env zsh

# nvm - node package manager
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

# Installing NVM
export NVM_DIR="$XDG_DATA_HOME/nvm"
mkdir -p $XDG_DATA_HOME/nvm
print_message "nvm" "curl"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
if [ $? -ne 0 ]; then
    print_error "nvm" "curl"
    exit 1
fi
