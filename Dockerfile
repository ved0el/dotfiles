# Dotfiles Testing Environment
# This Dockerfile creates an isolated environment for testing dotfiles configurations

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTFILES_ROOT=/opt/dotfiles
ENV DOTFILES_PROFILE=develop
ENV DOTFILES_VERBOSE=true
ENV HOME=/root

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    zsh \
    vim \
    nano \
    htop \
    tree \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a test user for more realistic testing
RUN useradd -m -s /bin/zsh testuser && \
    mkdir -p /opt/dotfiles && \
    chown -R testuser:testuser /opt/dotfiles

# Set up the dotfiles directory
WORKDIR /opt/dotfiles

# Copy dotfiles for testing
COPY . .

# Make scripts executable
RUN chmod +x bin/dotfiles && \
    find . -name "*.zsh" -type f -exec chmod +x {} \;

# Pre-create sheldon config directory to prevent lock errors
RUN mkdir -p /root/.config/sheldon && \
    cp config/sheldon/plugins.toml /root/.config/sheldon/ 2>/dev/null || true

# Set zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Create entrypoint script for testing
RUN cat > /usr/local/bin/test-dotfiles << 'EOF'
#!/bin/bash

echo "🧪 Dotfiles Testing Environment"
echo "==============================="

# Set up environment
export DOTFILES_ROOT=/opt/dotfiles
export DOTFILES_PROFILE="${DOTFILES_PROFILE:-develop}"
export DOTFILES_VERBOSE="${DOTFILES_VERBOSE:-true}"
export HOME=/root

echo "📋 Configuration:"
echo "  Profile: $DOTFILES_PROFILE"
echo "  Verbose: $DOTFILES_VERBOSE"
echo "  Root: $DOTFILES_ROOT"
echo ""

# Run the dotfiles installer
if [[ "$1" == "install" ]]; then
    echo "🚀 Installing dotfiles..."
    "$DOTFILES_ROOT/bin/dotfiles" install
elif [[ "$1" == "test" ]]; then
    echo "🧪 Testing shell startup..."
    time zsh -c "source ~/.zshrc && echo '✅ Shell startup successful'"
elif [[ "$1" == "debug" ]]; then
    echo "🔍 Debug mode - starting interactive shell..."
    exec zsh
else
    echo "📖 Usage: test-dotfiles [install|test|debug]"
    echo ""
    echo "Commands:"
    echo "  install - Install dotfiles"
    echo "  test    - Test shell startup performance"
    echo "  debug   - Start interactive shell for debugging"
fi
EOF

RUN chmod +x /usr/local/bin/test-dotfiles

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/test-dotfiles"]
CMD ["debug"]
