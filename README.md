# Dotfiles – Fast, profile-based setup

Clean, cross-platform dotfiles with profile-based installs and a simple, extensible package system.

## Install

```bash
# Interactive (recommended)
bash <(curl -fsSL https://tinyurl.com/get-dotfiles)

# Non-interactive
curl -fsSL https://tinyurl.com/get-dotfiles | DOTFILES_PROFILE=server bash
```

## Profiles

Profiles are cumulative — each includes everything below it.

| Profile | Tools |
|---------|-------|
| `minimal` | sheldon, tmux |
| `server` | minimal + bat, eza, fd, fzf, ripgrep, tealdeer, zoxide |
| `develop` | server + nvm, pyenv, goenv |

Switch profile anytime:

```bash
dotfiles profile server
```

## Project structure

```
~/.dotfiles/
├── zsh/
│   ├── core/           # Always-loaded modules (options, history, completion, aliases, theme, zcompile)
│   ├── lib/            # Shared libraries (platform, installer, lazy)
│   └── packages/
│       ├── minimal/    # sheldon, tmux
│       ├── server/     # bat, eza, fd, fzf, ripgrep, tealdeer, zoxide
│       └── develop/    # nvm, pyenv, goenv
├── bin/
│   └── dotfiles        # CLI (bash)
├── config/             # App configs (sheldon, bat, tealdeer, ripgrep, yabai, skhd)
├── docs/               # Architecture, requirements, guides
├── zshrc               # Shell entry point (~40 lines)
├── zshenv              # Env var template (not symlinked — CLI manages ~/.zshenv)
└── tmux.conf
```

## Package system

Each tool is a single self-contained `.zsh` file in `zsh/packages/<tier>/`. No other file changes when adding a package.

```zsh
#!/usr/bin/env zsh

PKG_NAME="mytool"
PKG_DESC="Short description"

pkg_install() {
    brew install mytool   # Optional: override OS package manager
}

pkg_init() {
    export MYTOOL_OPTS="--fast"
    alias mt="mytool"
}

init_package_template "$PKG_NAME"
```

See [`docs/guides/adding-a-package.md`](docs/guides/adding-a-package.md) for the full guide including lazy loading.

## CLI commands

```bash
dotfiles                  # interactive menu
dotfiles install          # install all packages for current profile
dotfiles link             # create/recreate symlinks
dotfiles verify           # check symlinks + report missing packages
dotfiles profile develop  # switch profile (persists across sessions)
dotfiles update           # pull latest changes
dotfiles uninstall        # remove symlinks and config
```

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_ROOT` | `~/.dotfiles` | Repository location |
| `DOTFILES_PROFILE` | `minimal` | Active profile |
| `DOTFILES_VERBOSE` | `false` | Enable verbose output |

## Troubleshooting

See [`docs/guides/troubleshooting.md`](docs/guides/troubleshooting.md) for common issues.

Quick checks:

```bash
# Shell startup time
for i in 1 2 3; do time zsh -i -c exit; done

# Check what's missing
dotfiles verify

# Force completion rebuild
rm -f ~/.zcompdump && exec zsh
```

---

MIT Licensed. See `docs/guides/adding-a-package.md` to add tools.
