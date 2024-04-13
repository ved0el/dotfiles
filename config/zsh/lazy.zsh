# Installing NVM
if ! command -v nvm &> /dev/null; then
    echo "NVM is not installed. Installing now..."
    # Install NVM
    export NVM_DIR="$HOME/.nvm"
    mkdir $HOME/.nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    # Load NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi
