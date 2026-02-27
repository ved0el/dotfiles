# Requirements

## Project Goals

A cross-platform, profile-based zsh configuration system that:

- Installs fast (lazy loading keeps shell startup under 200ms)
- Works identically on macOS and common Linux distros
- Scales from a minimal server setup to a full development environment
- Is easy to extend with new tools without touching core logic

## Non-Goals

- GUI / desktop environment configuration (window managers like yabai/skhd are included as config files only, not managed as packages)
- Fish or Bash support — zsh only
- Package version pinning or lockfiles

---

## Functional Requirements

### FR-1: Profile System

The system must support three cumulative profiles:

| Profile   | Tier | Tools included |
|-----------|------|----------------|
| `minimal` | `m`  | sheldon, tmux |
| `server`  | `s`  | minimal + bat, fzf, eza, fd, ripgrep, tealdeer, zoxide |
| `develop` | `d`  | server + nvm, pyenv, goenv, curlie |

- Each profile must include all tools from lower tiers (cumulative, not exclusive)
- The active profile is set via `DOTFILES_PROFILE` environment variable
- Switching profiles must not require re-installation — only `source ~/.zshrc`

### FR-2: Package System

Each tool must be defined as a self-contained package file under `zshrc.d/pkg/`.

A package file must be able to:
- Declare installation steps (`pkg_install`)
- Declare post-install setup (`pkg_post_install`)
- Declare runtime initialization (`pkg_init`)
- Be conditionally skipped without errors if the tool is not installed

Installation must only run when `DOTFILES_VERBOSE=true` (i.e. during explicit `dotfiles install`), never silently on shell startup.

### FR-3: Lazy Loading

Tools with slow startup (nvm, pyenv, goenv) must be lazy-loaded:
- Shell wrappers intercept the first invocation of the tool's commands
- On first use, the real tool is initialized and the wrapper is replaced
- Subsequent calls invoke the real command directly with no overhead

### FR-4: Symlink Management

The `bin/dotfiles` CLI must manage symlinks from the dotfiles repo to `$HOME`:
- Root-level config files → `$HOME/.<filename>`
- `config/` subtree → `$HOME/.config/<tool>/`
- Must handle already-existing targets gracefully (skip, not overwrite)
- Must support a `verify` operation to report broken or missing links

### FR-5: Cross-Platform Package Installation

Package installation must auto-detect the OS and use the correct package manager:

| Platform       | Package Manager |
|----------------|-----------------|
| macOS          | Homebrew (`brew`) |
| Ubuntu / Debian | `apt` |
| Fedora / RHEL / Rocky / Alma | `dnf`, `yum` |
| Arch / Manjaro | `pacman` |
| openSUSE       | `zypper` |
| FreeBSD        | `pkg` |

### FR-6: CLI (`bin/dotfiles`)

The `bin/dotfiles` command must support:

```
dotfiles install              # install packages for current profile
dotfiles update               # pull latest and re-install
dotfiles uninstall            # remove all symlinks and config
dotfiles profile <name>       # switch active profile
dotfiles verify               # check symlinks and installation state
```

---

## Non-Functional Requirements

### NFR-1: Startup Performance

- Shell startup must complete in < 200ms on a modern machine
- Heavy tools (nvm, pyenv, goenv) must not block startup
- `compinit` must run only once per day (cached via `~/.zcompdump`)

### NFR-2: Portability

- All zsh code must be compatible with zsh 5.8+
- No reliance on GNU-specific flags (use POSIX-compatible alternatives)
- macOS and Linux behavior must be functionally equivalent for all `m` and `s` tier packages

### NFR-3: Idempotency

- Running `dotfiles install` multiple times must produce the same result
- Re-sourcing `~/.zshrc` must not produce errors or duplicate state
- Package init functions must be safe to call more than once

### NFR-4: Failure Isolation

- A failing package must not prevent other packages from loading
- Errors must be surfaced clearly when `DOTFILES_VERBOSE=true`
- Silent failures are acceptable on normal shell startup (no installation noise)

### NFR-5: Extensibility

- Adding a new package must require creating exactly one file in `zshrc.d/pkg/`
- No core file should need modification to add a new tool
- Package files follow a documented naming convention and lifecycle API

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_ROOT` | `~/.dotfiles` | Absolute path to the dotfiles repo |
| `DOTFILES_PROFILE` | `minimal` | Active profile: `minimal`, `server`, or `develop` |
| `DOTFILES_VERBOSE` | `false` | Set to `true` to enable install logging and trigger package installation |
| `DOTFILES_FORCE_INSTALL` | `false` | Force re-installation even if tool is already present |

---

## Constraints

- The main entry point (`zshrc`) must remain < 60 lines
- Package files must be self-contained — they may only depend on functions from `lib/install_helper.zsh` and `lib/lazy_load_wrapper.zsh`
- No global state mutation outside of standard environment variable exports
- The `bin/dotfiles` CLI is Bash, all other files are zsh
