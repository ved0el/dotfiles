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
| `server` | minimal + bat, eza, fd, fzf, jq, ripgrep, tealdeer, zoxide, mise |

Switch profile anytime:

```bash
dotfiles profile server
```

## Project structure

```
~/.dotfiles/
├── zsh/
│   ├── core/           # Always-loaded modules (options, history, completion, aliases, theme, zcompile)
│   ├── lib/            # Shared libraries (platform, installer)
│   └── packages/
│       ├── minimal/    # sheldon, tmux
│       └── server/     # bat, eza, fd, fzf, jq, ripgrep, tealdeer, zoxide, mise
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

See [`docs/guides/adding-a-package.md`](docs/guides/adding-a-package.md) for the full lifecycle reference.

## CLI commands

```bash
dotfiles                  # interactive menu
dotfiles install          # install all packages for current profile
dotfiles link             # create/recreate symlinks
dotfiles verify           # check symlinks + report missing packages
dotfiles profile server   # switch profile (persists across sessions)
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

## Documentation

- [Architecture](docs/architecture.md) — system design, lifecycle, internals
- [Adding a package](docs/guides/adding-a-package.md) — extension guide
- [Troubleshooting](docs/guides/troubleshooting.md) — common issues
- [Requirements](docs/requirements.md) — functional and non-functional spec

## Contributing

Pull requests welcome. Please:

1. Open an issue first for non-trivial changes.
2. Add or update tests where applicable.
3. Run `dotfiles verify` and confirm `time zsh -i -c exit` stays under 200 ms.

## License

Released under the MIT License.
