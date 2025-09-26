## dotfiles — one‑command setup for macOS and Ubuntu/Debian

This repository configures a fresh machine with minimal tools and links your dotfiles.

- Tools: git, zsh, sheldon (plugin manager), tmux (skipped on SSH/IDE)
- Platforms: macOS and Ubuntu/Debian Linux

### Quick start (local clone)

```bash
./install.sh
```

The installer will:
- Detect OS and environment (SSH/IDE)
- Install required packages
- Link dotfiles with backups
- Optionally set your default shell to `zsh` (best‑effort)

### One‑liner (after you host this repo)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<your>/<repo>/main/install.sh)"
```

### Structure

```
dotfiles/
  git/.gitconfig
  zsh/.zshrc
  sheldon/plugins.toml
  tmux/.tmux.conf
scripts/
  lib/{utils.sh,os.sh,pkg.sh,link.sh}
  steps/{install_packages.sh,link_dotfiles.sh}
install.sh
```

### Notes
- tmux is skipped when running over SSH or inside an IDE terminal like VS Code.
- Existing files are safely backed up to `~/.dotfiles_backup` before linking.
- You can safely re‑run the installer; it is idempotent.

# dotfiles - make your life simple

## Getting started

1. Manual install

```zsh
curl -o install.sh https://raw.githubusercontent.com/ved0el/dotfiles/main/bin/install.sh
bash install.sh
```
