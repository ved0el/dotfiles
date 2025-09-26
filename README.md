# Modern Dotfiles Management System

A clean, cross-platform dotfiles management system designed for developers who want a powerful, consistent environment across macOS and Linux systems.

## ✨ Features

- **🚀 One-Command Setup**: Single command installation for new machines
- **🔄 Cross-Platform**: Supports Ubuntu/Debian, macOS, Fedora, and Arch Linux
- **🧠 Smart Detection**: Automatically detects SSH and IDE environments
- **⚡ Performance Focused**: Optimized zsh configuration with fast plugin loading
- **🛠️ Modern Tools**: Includes best-in-class command-line tools
- **🔧 Modular Design**: Clean, maintainable configuration structure

## 🎯 Supported Tools

### Essential Tools (Always Installed)
- **Git** - Version control
- **Zsh** - Modern shell
- **Sheldon** - Fast ZSH plugin manager

### Optional Tools (Conditional)
- **Tmux** - Terminal multiplexer (skipped in SSH/IDE environments)

### Modern CLI Tools (Auto-installed)
- **bat** - Modern `cat` replacement with syntax highlighting
- **eza** - Modern `ls` replacement with icons and git integration
- **fd** - Modern `find` replacement
- **ripgrep** - Ultra-fast grep alternative
- **zoxide** - Smart `cd` command that learns your habits
- **fzf** - Fuzzy finder for everything

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ved0el/dotfiles/main/install.sh | bash
```

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ved0el/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Run the installer:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Restart your terminal or reload zsh:**
   ```bash
   exec zsh
   ```

## 🏗️ Architecture

```
~/.dotfiles/
├── install.sh              # Main installation script
├── zshrc                   # Main ZSH configuration
├── tmux.conf              # Tmux configuration
├── gitconfig              # Git configuration
├── p10k.zsh               # Powerlevel10k theme config
├── config/
│   └── sheldon/
│       └── plugins.toml   # Plugin definitions
└── zshrc.d/
    ├── core/              # Core shell configuration
    │   ├── init.zsh       # Shell initialization
    │   ├── options.zsh    # ZSH options
    │   ├── history.zsh    # History configuration
    │   └── alias.zsh      # Aliases and shortcuts
    ├── functions/         # Custom functions
    │   └── package_installer.zsh
    └── plugins/           # Plugin configurations
        ├── sheldon.zsh    # Sheldon setup
        └── tmux.zsh       # Tmux auto-attach
```

## 🔧 Configuration

### Environment Detection

The system automatically detects your environment and adapts accordingly:

- **SSH Sessions**: Tmux is not auto-started to avoid nested sessions
- **IDE Environments**: Tmux is skipped in VSCode, Cursor, and similar editors
- **Regular Terminals**: Full tmux integration with session management

### Customization

#### Git Configuration
Update your Git user information:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

#### ZSH Configuration
All configuration files are modular and located in `~/.dotfiles/zshrc.d/`:
- Edit `core/alias.zsh` for custom aliases
- Edit `core/options.zsh` for ZSH behavior
- Add custom functions to `functions/`

#### Plugin Management
Plugins are managed via Sheldon. Edit `config/sheldon/plugins.toml` to add or remove plugins:
```toml
[plugins.your-plugin]
github = "user/repo"
apply = ["defer"]  # Optional: defer loading for performance
```

Then reload:
```bash
sheldon lock && exec zsh
```

## 🛠️ Package Managers

The installer automatically detects and uses the appropriate package manager:

| OS | Package Manager |
|----|-----------------|
| macOS | Homebrew |
| Ubuntu/Debian | apt |
| Fedora/RHEL/CentOS | dnf/yum |
| Arch/Manjaro | pacman |

## 📋 Manual Tool Installation

If you prefer to install tools manually:

### Homebrew (macOS)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Sheldon (All platforms)
```bash
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
  | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
```

## 🎨 Themes and Appearance

### Powerlevel10k
The configuration includes Powerlevel10k for a beautiful, informative prompt. Customize it by running:
```bash
p10k configure
```

### Terminal Themes
For best results, use a terminal with:
- True color support (24-bit)
- Nerd Font or similar icon font
- Dark theme

Recommended terminals:
- **macOS**: iTerm2, Alacritty, Wezterm
- **Linux**: Alacritty, Wezterm, Gnome Terminal

## 🔄 Updates and Maintenance

### Update Dotfiles
```bash
cd ~/.dotfiles
git pull
exec zsh
```

### Update Plugins
```bash
sheldon lock
```

### Update Tools
```bash
# Homebrew (macOS)
brew upgrade

# Ubuntu/Debian
sudo apt update && sudo apt upgrade

# Fedora
sudo dnf upgrade

# Arch
sudo pacman -Syu
```

## 🆘 Troubleshooting

### Common Issues

**Plugin loading is slow:**
- Plugins are automatically deferred for performance
- Try `sheldon lock` to rebuild cache

**Tmux not starting:**
- Check if you're in SSH: `echo $SSH_CONNECTION`
- Check if you're in an IDE: `echo $TERM_PROGRAM`
- Tmux is intentionally disabled in these environments

**Command not found errors:**
- Ensure `~/.local/bin` is in your PATH
- Run `source ~/.zshrc` to reload configuration

**Git authentication issues:**
- Set up SSH keys or configure credential helpers
- Check Git configuration: `git config --global --list`

### Debug Mode
Enable debug output:
```bash
DOTFILES_DEBUG=1 exec zsh
```

### Reset Configuration
To start fresh:
```bash
cd ~/.dotfiles
git stash  # Save any local changes
git pull origin main
exec zsh
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Commit with descriptive messages
5. Push and create a pull request

### Development Guidelines

- Keep configurations modular and well-commented
- Test on multiple platforms when possible
- Use defensive programming (check for command existence)
- Follow the existing code style and structure

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Sheldon](https://github.com/rossmacarthur/sheldon) - Fast ZSH plugin manager
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Beautiful ZSH theme
- [TMux Plugin Manager](https://github.com/tmux-plugins/tpm) - Tmux plugin ecosystem
- The Rust community for amazing CLI tools

---

**Happy coding! 🚀**