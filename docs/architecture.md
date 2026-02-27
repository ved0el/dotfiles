# Architecture

## Overview

The dotfiles system is composed of four layers:

```
┌─────────────────────────────────────────────────────────┐
│  bin/dotfiles   (Bash CLI — install, update, symlinks)  │
├─────────────────────────────────────────────────────────┤
│  zshrc          (Entry point — sources core/ then pkg/) │
├──────────────────────────┬──────────────────────────────┤
│  zshrc.d/core/           │  zshrc.d/lib/               │
│  Always-loaded zsh config│  Shared library functions   │
├──────────────────────────┴──────────────────────────────┤
│  zshrc.d/pkg/   (One file per tool, profile-filtered)   │
└─────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
.dotfiles/
├── bin/
│   └── dotfiles              # CLI: install, update, uninstall, verify, profile
├── config/                   # Tool configs, symlinked to ~/.config/<tool>/
│   ├── bat/                  # bat theme and config
│   ├── ripgrep/              # ripgreprc default flags
│   ├── sheldon/
│   │   └── plugins.toml      # zsh plugin manager config
│   ├── skhd/                 # macOS hotkey daemon (macOS only, not a managed pkg)
│   ├── tealdeer/             # tldr page cache config
│   └── yabai/                # macOS tiling WM (macOS only, not a managed pkg)
├── docs/                     # This documentation
├── scripts/                  # Utility scripts (setup, alerting)
├── zshrc.d/
│   ├── core/                 # Always-loaded modules (numbered, sequential)
│   ├── lib/                  # Shared zsh libraries
│   └── pkg/                  # Package files (NNN_tier_name.zsh)
├── p10k.zsh                  # Powerlevel10k theme configuration
├── tmux.conf                 # Tmux configuration
├── zshrc                     # Main zsh entry point
└── zshenv                    # Dotfiles env vars (DOTFILES_ROOT, PROFILE, VERBOSE)
```

---

## Shell Startup Flow

When a new zsh session starts, the following happens in order:

```
~/.zshenv
  └── exports DOTFILES_ROOT, DOTFILES_PROFILE, DOTFILES_VERBOSE

~/.zshrc  →  $DOTFILES_ROOT/zshrc
  │
  ├── 1. Source zshrc.d/core/*.zsh  (alphabetical, always loaded)
  │       00_core_config.zsh        # TERM, base PATH additions
  │       05_completion_init.zsh    # zstyle completion config
  │       10_perf_options.zsh       # setopt declarations
  │       20_zcompile.zsh           # background zcompile for .zwc files
  │       30_env_aliases.zsh        # aliases (cd, ls, ll, etc.)
  │       101_fzf_history.zsh       # fzf keybindings for history search
  │       200_theme_loader.zsh      # Powerlevel10k instant prompt + theme
  │
  ├── 2. Source zshrc.d/lib/install_helper.zsh
  │       Provides: init_package_template, is_package_installed,
  │                 _dotfiles_install_package, _dotfiles_log_*, utils
  │
  ├── 3. Source zshrc.d/lib/lazy_load_wrapper.zsh
  │       Provides: create_lazy_wrapper
  │
  └── 4. For each pkg file matching the active profile pattern:
          Source zshrc.d/pkg/NNN_tier_name.zsh
          Each file calls init_package_template which either:
            a) Runs pkg_init if tool is already installed
            b) Skips silently if tool is not installed (normal startup)
            c) Installs then initializes if DOTFILES_VERBOSE=true
```

**Key invariant**: Installation never happens on normal shell startup. The `DOTFILES_VERBOSE=true` flag gates all installation logic.

---

## Profile System

Profiles are cumulative. Each profile activates all tiers at or below it:

| Profile   | Active tiers | pkg file patterns loaded |
|-----------|-------------|--------------------------|
| `minimal` | `m`         | `*_m_*.zsh`              |
| `server`  | `m`, `s`    | `*_m_*.zsh`, `*_s_*.zsh` |
| `develop` | `m`, `s`, `d` | `*_m_*.zsh`, `*_s_*.zsh`, `*_d_*.zsh` |

The profile is read from `$DOTFILES_PROFILE` at startup. Changing the profile takes effect on the next `source ~/.zshrc`.

---

## Package System

### File Naming Convention

```
NNN_{tier}_{name}.zsh

NNN   — three-digit load order number (100=sheldon, 200=server tools, 300=dev tools)
tier  — m (minimal), s (server), or d (develop)
name  — tool name (lowercase, no spaces)
```

Examples:
- `100_m_sheldon.zsh` — sheldon, minimal tier, loads first
- `200_s_bat.zsh`     — bat, server tier
- `300_d_nvm.zsh`     — nvm, develop tier

### Package Lifecycle API

Each package file sets metadata variables and optionally defines hook functions, then calls `init_package_template` to hand off to the package engine.

```zsh
#!/usr/bin/env zsh

PKG_NAME="toolname"          # Package name (used in log messages)
PKG_DESC="Short description" # Used in install prompts
PKG_CMD="toolname"           # Command to check if installed (defaults to PKG_NAME)

# Optional: runs before installation
pkg_pre_install() {
    # precondition checks, dependency setup
}

# Optional: custom installer (if omitted, _dotfiles_install_package is used)
pkg_install() {
    # custom install logic (e.g. curl installer, git clone)
}

# Optional: runs after successful installation
pkg_post_install() {
    # setup, config file copy, symlinks
}

# Optional: runs on every shell start if tool is installed
pkg_init() {
    # export env vars, source tool init scripts, set up lazy wrappers
}

init_package_template "$PKG_NAME"
```

**Rules:**
- All hook functions are optional. Omit them if not needed.
- `pkg_init` runs on every shell startup when the tool is installed — keep it fast.
- `pkg_install` overrides the default OS package manager. Use it for tools not available in standard repos (e.g. curl-based installers, git clone).
- Hook functions are unset after `init_package_template` returns, so they do not pollute the shell environment.

### init_package_template Flow

```
init_package_template "pkgname"
  │
  ├── is_package_installed PKG_CMD?
  │     Yes → run pkg_init → done
  │     No  → DOTFILES_VERBOSE=true?
  │               No  → silent skip → done
  │               Yes → installation flow:
  │                       pkg_pre_install (if defined)
  │                       pkg_install OR _dotfiles_install_package
  │                       verify install (is_package_installed again)
  │                       pkg_post_install (if defined)
  │                       pkg_init
  └── done
```

### Standard Package Example

```zsh
#!/usr/bin/env zsh

PKG_NAME="bat"
PKG_DESC="A cat clone with syntax highlighting and Git integration"

pkg_post_install() {
    # Ubuntu/Debian ships bat as 'batcat'; create a compat symlink
    [[ "$(uname -s)" == "Linux" ]] && ! command -v batcat &>/dev/null && \
        create_symlink "$(which bat)" "/usr/local/bin/batcat"
}

pkg_init() {
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
}

init_package_template "$PKG_NAME"
```

### Custom Installer Example

For tools not in system package managers (NVM, pyenv, goenv):

```zsh
#!/usr/bin/env zsh

PKG_NAME="pyenv"
PKG_DESC="Python Version Manager"

pkg_install() {
    curl https://pyenv.run | bash
}

pkg_init() {
    source "$DOTFILES_ROOT/zshrc.d/lib/pyenv_lazy.zsh"
}

init_package_template "$PKG_NAME"
```

---

## Lazy Loading

Heavy tools (nvm, pyenv, goenv) take 100–500ms to initialize. Lazy loading defers that cost until the first time a related command is actually used.

### Mechanism

`create_lazy_wrapper "cmd" "load_func" [extra_cmds...]` creates shell functions that:

1. Intercept the first call to `cmd` (and any `extra_cmds`)
2. Run `load_func` to perform real initialization
3. Replace themselves with the real commands
4. Re-invoke the original command with original arguments

```zsh
# Before first use — these are shell functions (wrappers):
$ type node
node is a shell function

# After first use of `node` — wrapper triggers lazy load:
$ node --version
# (nvm initializes here, ~200ms delay, once only)
v22.0.0

# Now the real command is in PATH:
$ type node
node is /Users/user/.nvm/versions/node/v22.0.0/bin/node
```

### Lazy Loader Pattern

A `lib/*_lazy.zsh` file follows this structure:

```zsh
lazy_load_TOOL() {
    export TOOL_ROOT="$HOME/.tool"
    export PATH="$TOOL_ROOT/bin:$PATH"
    eval "$(tool init -)"  # or: source "$TOOL_ROOT/tool.sh"
}

[[ -d "${HOME}/.tool" ]] && \
    create_lazy_wrapper "tool" "lazy_load_TOOL" "tool-extra-cmd"
```

---

## Symlink Management

`bin/dotfiles` manages two categories of symlinks:

| Source | Target | Example |
|--------|--------|---------|
| `$DOTFILES_ROOT/<file>` | `$HOME/.<file>` | `zshrc` → `~/.zshrc` |
| `$DOTFILES_ROOT/config/<tool>/` | `$HOME/.config/<tool>/` | `config/bat/` → `~/.config/bat/` |

Excluded from symlinking (via `EXCLUDE_PATTERNS`):
- `README.md`, `CHANGELOG.md`, `CLAUDE.md`
- `docs/`, `scripts/`, `bin/`, `.git/`, `.gitignore`
- `*.zwc` compiled zsh files

---

## Shared Libraries

### `lib/install_helper.zsh`

Sourced unconditionally in `zshrc`. Provides:

| Function | Purpose |
|----------|---------|
| `init_package_template` | Main package lifecycle orchestrator |
| `is_package_installed cmd` | Returns 0 if `cmd` is in PATH and executable |
| `_dotfiles_install_package name` | OS-aware package manager install |
| `_dotfiles_log_debug/info/warning/error/success` | Leveled logging (most only shown when `DOTFILES_VERBOSE=true`) |
| `ensure_directory path` | `mkdir -p` wrapper |
| `copy_if_missing src dst` | Copy only if destination doesn't exist |
| `create_symlink target link` | `ln -sf` wrapper, skips if link already exists |

### `lib/lazy_load_wrapper.zsh`

Sourced unconditionally in `zshrc`. Provides:

| Function | Purpose |
|----------|---------|
| `create_lazy_wrapper cmd load_func [extras...]` | Register lazy-load wrappers for a command group |

---

## Plugin Management (Sheldon)

Zsh plugins are managed by [sheldon](https://sheldon.cli.rs). Config lives at `config/sheldon/plugins.toml` (symlinked to `~/.config/sheldon/plugins.toml`).

Plugin load order (from `plugins.toml`):

1. `zsh-defer` — deferred loading utility (loaded immediately)
2. `fast-syntax-highlighting` — command syntax highlighting (loaded immediately)
3. `zsh-completions` — additional completion definitions (loaded immediately, must precede compinit)
4. `fzf-tab` — fzf-powered tab completion UI (deferred)
5. `zsh-autosuggestions` — fish-style inline suggestions (deferred)
6. `k` — colorized directory listings (deferred)
7. `ni` — package manager detection (deferred)
8. `zsh-nvm` — nvm integration (deferred)
9. `powerlevel10k` — prompt theme (deferred, instant prompt precaches)

**compinit ordering**: `compinit` must run after `zsh-completions` adds to `fpath`. It is called in `pkg_init` of `100_m_sheldon.zsh`, immediately after `eval "$(sheldon source)"`.

---

## Cross-Platform Notes

| Feature | macOS | Linux |
|---------|-------|-------|
| Package manager | Homebrew | apt / dnf / pacman / zypper |
| Shell | zsh (system) | zsh (must install) |
| `bat` command name | `bat` | `bat` or `batcat` (pkg handles compat) |
| yabai / skhd | Supported (config only) | Not applicable |
| pyenv install deps | Xcode CLT | build-essential, libssl-dev, etc. |
| NVM install | curl installer | curl installer |
