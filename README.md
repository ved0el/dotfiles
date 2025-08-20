# 🚀 Dotfiles – Fast, profile-based setup

Clean, cross‑platform dotfiles with profile‑based installs and a simple, extensible package system.

## Install

```bash
# Interactive (recommended)
bash <(curl -fsSL https://tinyurl.com/get-dotfiles)

# Non‑interactive examples
curl -fsSL https://tinyurl.com/get-dotfiles | DOTFILES_PROFILE=server bash
curl -fsSL https://tinyurl.com/get-dotfiles | DOTFILES_ROOT=~/.dotfiles bash
```

## Profiles

| Profile | What you get |
|--------|---------------|
| minimal | sheldon, tmux |
| server | minimal + bat, fzf, eza, fd, ripgrep, tealdeer, zoxide |
| develop | server + nvm, pyenv, goenv, curlie |

Set profile anytime:

```bash
export DOTFILES_PROFILE=server && source ~/.zshrc
```

## Project structure (core)

```bash
zshrc.d/
  functions/
    package_installer.zsh        # Entry – runs package scripts
    lib/
      logging.zsh               # log_info/log_error/…
      platform.zsh              # get_platform/get_package_manager
      profile.zsh               # get_profile/should_install_package
      utils.zsh                 # is_package_installed/check_dependencies
  packages/                      # One file per package (see template)
    00_template.zsh
```

## Package system (general, no hardcoding)

Each package file declares metadata and platform install methods, then calls the installer.

Filename convention: `NNN_{m|s|d}_name.zsh` where m=minimal, s=server, d=develop.

Minimal example (see `zshrc.d/packages/00_template.zsh`):

```zsh
PACKAGE_NAME="tool"
PACKAGE_DESC="Useful tool"
PACKAGE_DEPS=""  # space‑separated CLI deps if any

typeset -A install_methods
install_methods=(
  [brew]="brew install tool"
  [apt]="sudo apt update && sudo apt install -y tool"
  [custom]="echo 'manual install here'"
)

pre_install()  { return 0 }
post_install() { is_package_installed "$PACKAGE_NAME" }
init()         { return 0 }

# Hand off to the general installer
call_install_package $PACKAGE_NAME $PACKAGE_DESC $PACKAGE_DEPS "${(@kv)install_methods}"
```

## Commands

```bash
dotfiles            # interactive
dotfiles install    # install/update
dotfiles uninstall  # remove links and config
dotfiles profile develop
```

## Environment

| Var | Default | Purpose |
|-----|---------|---------|
| DOTFILES_ROOT | ~/.dotfiles | install location |
| DOTFILES_PROFILE | minimal | minimal/server/develop |
| DOTFILES_BRANCH | main | git branch |

## Uninstall

```bash
dotfiles uninstall
```

## Troubleshooting

- On Ubuntu/Debian, ensure `curl` exists for custom installers
- Force re‑install: `DOTFILES_FORCE_INSTALL=1 zsh`
- Clear install marker: `rm ~/.cache/.dotfiles_installed`

---

MIT Licensed. PRs welcome. See `zshrc.d/packages/00_template.zsh` to add tools.
