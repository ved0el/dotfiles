# 🚀 Dotfiles – Fast, Profile-Based Development Environment

A clean, cross-platform dotfiles system with profile-based installs and a simple, extensible package management system. Built for developers who want a fast, reliable, and customizable shell environment.

## ✨ Features

- **🎯 Profile-Based Installation**: Choose from `minimal`, `server`, or `develop` profiles
- **⚡ Fast Shell Startup**: Optimized with zsh-defer and efficient plugin loading
- **🔧 Cross-Platform**: Works on macOS, Linux, and FreeBSD
- **📦 Smart Package Management**: Auto-installs tools when first used
- **🐳 Docker Testing**: Isolated testing environment for development
- **🔍 Comprehensive Debugging**: Built-in debugging and validation tools
- **🎨 Modern UI**: Professional installer with colored output and progress indicators

## 🚀 Quick Start

### Interactive Installation (Recommended)
```bash
bash <(curl -fsSL https://tinyurl.com/get-dotfiles)
```

### Non-Interactive Installation
```bash
# Server profile
curl -fsSL https://tinyurl.com/get-dotfiles | DOTFILES_PROFILE=server bash

# Custom location
curl -fsSL https://tinyurl.com/get-dotfiles | DOTFILES_ROOT=~/.dotfiles bash
```

## 📋 Profiles

| Profile | Description | Tools Included |
|---------|-------------|----------------|
| **minimal** | Shell essentials | sheldon, tmux, zsh-defer |
| **server** | Server utilities | minimal + bat, fzf, eza, fd, ripgrep, tealdeer, zoxide |
| **develop** | Full development | server + nvm, pyenv, goenv, curlie |

### Switch Profiles Anytime
```bash
export DOTFILES_PROFILE=server && source ~/.zshrc
```

## 🏗️ Project Structure

```
dotfiles/
├── bin/
│   └── dotfiles                 # Main installer script
├── config/
│   ├── sheldon/
│   │   └── plugins.toml         # Plugin configuration
│   └── tealdeer/
│       └── config.toml          # Tealdeer configuration
├── zshrc.d/
│   ├── core/                    # Core shell configuration
│   │   ├── 00_core_config.zsh   # Main configuration loader
│   │   ├── 10_perf_options.zsh  # Performance optimizations
│   │   ├── 20_completion_options.zsh # Completion settings
│   │   ├── 30_sheldon_cache.zsh # Sheldon cache management
│   │   ├── 40_zcompile.zsh      # Zsh compilation
│   │   ├── 50_env_aliases.zsh   # Environment and aliases
│   │   ├── 60_package_manager.zsh # Package manager detection
│   │   └── 70_theme_loader.zsh  # Theme loading
│   ├── functions/
│   │   └── package_installer.zsh # Package management system
│   ├── packages/                # Package definitions
│   │   ├── 00_template.zsh      # Package template
│   │   ├── 100_m_sheldon.zsh    # Minimal: Sheldon
│   │   ├── 101_m_tmux.zsh       # Minimal: Tmux
│   │   ├── 200_s_bat.zsh        # Server: Bat
│   │   ├── 201_s_fzf.zsh        # Server: FZF
│   │   ├── 202_s_eza.zsh        # Server: Eza
│   │   ├── 203_s_fd.zsh         # Server: FD
│   │   ├── 204_s_ripgrep.zsh    # Server: Ripgrep
│   │   ├── 205_s_tealdeer.zsh   # Server: Tealdeer
│   │   ├── 206_s_zoxide.zsh     # Server: Zoxide
│   │   ├── 300_d_nvm.zsh        # Develop: NVM
│   │   ├── 301_d_pyenv.zsh      # Develop: Pyenv
│   │   ├── 302_d_goenv.zsh      # Develop: Goenv
│   │   └── 303_d_curlie.zsh     # Develop: Curlie
│   └── plugins/
│       └── tmux.zsh             # Tmux plugin
├── zshrc                        # Main zsh configuration
├── p10k.zsh                     # Powerlevel10k theme config
├── tmux.conf                    # Tmux configuration
├── Makefile                     # Development commands
├── docker-compose.yml           # Docker testing setup
├── Dockerfile                   # Docker test environment
└── README.md                    # This file
```

## 📦 Package System

The package system is designed to be simple, extensible, and fast. Each package follows a consistent pattern:

### Package Naming Convention
- `100-199_m_*.zsh` - Minimal profile packages
- `200-299_s_*.zsh` - Server profile packages  
- `300-399_d_*.zsh` - Develop profile packages

### Package Structure
```zsh
#!/usr/bin/env zsh

# Package information
PACKAGE_NAME="tool_name"
PACKAGE_DESC="Description of the tool"
PACKAGE_DEPS=""  # Dependencies (space-separated)

# Pre-installation setup (optional)
pre_install() {
  # Setup before installation
  return 0
}

# Post-installation setup (optional)
post_install() {
  # Setup after installation
  return 0
}

# Package initialization (always runs)
init() {
  # Environment setup (aliases, PATH, etc.)
  if is_package_installed "$PACKAGE_NAME"; then
    # Set up environment
    return 0
  fi
  return 1
}

# Installation logic
if ! is_package_installed "$PACKAGE_NAME"; then
  pre_install
  install_package_simple "$PACKAGE_NAME" "$PACKAGE_DESC"
  post_install
fi
```

## 🛠️ Development

### Prerequisites
- Zsh 5.0+
- Git
- Curl
- Make (optional)

### Development Commands
```bash
# Install dotfiles
make install

# Run tests
make test

# Validate configuration
make validate

# Performance testing
make perf

# Docker testing
make docker-build
make docker-run
make docker-shell

# Debug mode
make debug

# Clean caches
make clean
```

### Adding New Packages

1. **Copy the template**:
   ```bash
   cp zshrc.d/packages/00_template.zsh zshrc.d/packages/XXX_p_name.zsh
   ```

2. **Choose the right number**:
   - `100-199`: Minimal profile
   - `200-299`: Server profile
   - `300-399`: Develop profile

3. **Update package information**:
   ```zsh
   PACKAGE_NAME="your_tool"
   PACKAGE_DESC="Description of your tool"
   PACKAGE_DEPS="dependency1 dependency2"  # or "" for none
   ```

4. **Implement functions**:
   - `pre_install()`: Setup before installation
   - `post_install()`: Setup after installation
   - `init()`: Environment setup (always runs)

5. **Test your package**:
   ```bash
   make validate
   make test
   ```

## 🐳 Docker Testing

Test your dotfiles in an isolated environment:

```bash
# Build test image
make docker-build

# Run tests
make docker-run

# Interactive shell
make docker-shell

# Test all profiles
docker-compose up
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_ROOT` | `~/.dotfiles` | Installation directory |
| `DOTFILES_PROFILE` | `minimal` | Profile: minimal/server/develop |
| `DOTFILES_VERBOSE` | `false` | Enable verbose logging |
| `DOTFILES_BRANCH` | `main` | Git branch to install |
| `DOTFILES_REPO` | Auto-detected | Repository URL |

### Shell Configuration

The system uses a modular approach:

1. **Core Configuration** (`zshrc.d/core/`): Essential shell settings
2. **Package System** (`zshrc.d/packages/`): Tool installations and setup
3. **Plugins** (`zshrc.d/plugins/`): Additional shell plugins

## 🚀 Performance

The dotfiles are optimized for fast shell startup:

- **Zsh-defer**: Non-critical plugins load asynchronously
- **Compiled Zsh**: Automatic compilation of zsh files
- **Efficient Caching**: Smart caching of plugin and completion data
- **Minimal Synchronous Loading**: Only essential components load immediately

### Performance Testing
```bash
# Test startup time
make perf

# Check cache sizes
./bin/dotfiles-debug perf cache

# Test compilation
./bin/dotfiles-debug perf compilation
```

## 🔍 Debugging

Comprehensive debugging tools are included:

```bash
# Interactive debug menu
./bin/dotfiles debug

# System information
./bin/dotfiles-debug info

# Validate configuration
./bin/dotfiles-debug validate all

# Performance analysis
./bin/dotfiles-debug perf startup
```

## 📚 Commands

### Main Commands
```bash
dotfiles                    # Interactive menu
dotfiles install           # Install/update dotfiles
dotfiles update            # Update dotfiles
dotfiles uninstall         # Remove all dotfiles
dotfiles profile <name>    # Change profile
dotfiles packages          # Install packages
dotfiles verify            # Verify symlinks
dotfiles debug             # Debug tools
dotfiles help              # Show help
```

### Make Commands
```bash
make help                  # Show all commands
make install               # Install dotfiles
make test                  # Run test suite
make validate              # Validate configuration
make perf                  # Performance testing
make docker-build          # Build Docker image
make docker-run            # Run Docker tests
make docker-shell          # Docker shell
make debug                 # Debug mode
make clean                 # Clean caches
```

## 🛡️ Uninstallation

```bash
dotfiles uninstall
```

This will:
- Remove all symlinks
- Clean up configuration files
- Remove the dotfiles directory
- Restore your original shell environment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `make test`
5. Submit a pull request

### Development Workflow
```bash
# Clone and setup
git clone <your-fork>
cd dotfiles

# Make changes
# ... edit files ...

# Test changes
make validate
make test
make docker-build
make docker-run

# Commit and push
git add .
git commit -m "Add new feature"
git push origin feature-branch
```

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- [Sheldon](https://github.com/rossmacarthur/sheldon) - Fast plugin manager
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Zsh-defer](https://github.com/romkatv/zsh-defer) - Async plugin loading
- All the amazing open-source tools that make this possible

---

**Happy coding!** 🎉