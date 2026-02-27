# Architecture

## Overview

The system has four layers. Each layer has a single, clear responsibility:

```
┌─────────────────────────────────────────────────────────────┐
│  bin/dotfiles      Bash CLI — symlinks, install, update     │
├─────────────────────────────────────────────────────────────┤
│  zshrc             Entry point — sources core/ and pkgs     │
├───────────────────────────┬─────────────────────────────────┤
│  zsh/core/                │  zsh/lib/                       │
│  Sequential shell config  │  Shared library functions       │
├───────────────────────────┴─────────────────────────────────┤
│  zsh/packages/<tier>/     One file per tool, profile-gated  │
└─────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

This is the **target structure** (some paths are pending refactoring from the current layout):

```
.dotfiles/
├── bin/
│   └── dotfiles                    # Bash CLI: install, update, uninstall, verify, profile
│
├── config/                         # Tool configs → symlinked to ~/.config/<tool>/
│   ├── bat/                        # bat theme + config
│   ├── ripgrep/                    # ripgreprc default flags
│   ├── sheldon/
│   │   └── plugins.toml            # Sheldon plugin manager config
│   ├── skhd/                       # macOS hotkey daemon (not a managed package)
│   ├── tealdeer/                   # tldr cache config
│   └── yabai/                      # macOS tiling WM (not a managed package)
│
├── docs/
│   ├── requirements.md             # What the system must do
│   ├── architecture.md             # How it works (this file)
│   └── guides/
│       ├── adding-a-package.md     # Step-by-step for contributors
│       └── troubleshooting.md      # Debug guide
│
├── zsh/                            # All zsh configuration
│   ├── core/                       # Always-loaded modules, run in numeric order
│   │   ├── 10-options.zsh          # Shell options (setopt)
│   │   ├── 20-history.zsh          # History settings + fzf history keybinding
│   │   ├── 30-completion.zsh       # compinit + zstyle config (runs after sheldon)
│   │   ├── 40-aliases.zsh          # Aliases with runtime availability guards
│   │   └── 50-theme.zsh            # Powerlevel10k instant prompt + theme load
│   │
│   ├── lib/                        # Shared libraries — sourced before packages
│   │   ├── installer.zsh           # Package lifecycle engine + logging + utilities
│   │   ├── lazy.zsh                # Lazy loading (create_lazy_wrapper)
│   │   └── platform.zsh            # OS/distro detection helpers
│   │
│   └── packages/                   # One .zsh file per tool, grouped by tier
│       ├── minimal/
│       │   ├── sheldon.zsh         # Plugin manager (loads first in its tier)
│       │   └── tmux.zsh
│       ├── server/
│       │   ├── bat.zsh
│       │   ├── eza.zsh
│       │   ├── fd.zsh
│       │   ├── fzf.zsh
│       │   ├── ripgrep.zsh
│       │   ├── tealdeer.zsh
│       │   └── zoxide.zsh
│       └── develop/
│           ├── goenv.zsh
│           ├── nvm.zsh
│           └── pyenv.zsh
│
├── p10k.zsh                        # Powerlevel10k config → ~/.p10k.zsh
├── tmux.conf                       # Tmux config → ~/.tmux.conf
├── zshrc                           # Shell entry point → ~/.zshrc
└── zshenv                          # Dotfiles env vars → ~/.zshenv
```

**Key design decisions:**
- `zsh/` consolidates all zsh logic (replaces the current `zshrc.d/` directory)
- Packages are grouped in subdirectories by tier — no magic number prefixes needed
- Lazy loader logic lives **inside each package's `pkg_init()`** — no separate `*_lazy.zsh` files
- `zsh/lib/` has exactly three files, each with a single responsibility

---

## Shell Startup Flow

```
~/.zshenv  →  zshenv
  └── Exports DOTFILES_ROOT, DOTFILES_PROFILE, DOTFILES_VERBOSE, LANG

~/.zshrc  →  zshrc
  │
  ├── 1. Source zsh/core/*.zsh  (alphabetical = numeric order)
  │       10-options.zsh     — setopt (extended_glob, auto_cd, etc.)
  │       20-history.zsh     — HISTFILE, HISTSIZE, fzf Ctrl-R binding
  │       30-completion.zsh  — zstyle config (runs after sheldon sets fpath)
  │       40-aliases.zsh     — cd/ls/ll aliases with `command -v` guards
  │       50-theme.zsh       — Powerlevel10k instant prompt + p10k load
  │
  ├── 2. Source zsh/lib/installer.zsh   — package lifecycle engine
  │       Source zsh/lib/lazy.zsh       — create_lazy_wrapper
  │       Source zsh/lib/platform.zsh   — OS/distro detection
  │
  └── 3. Load packages for active profile:
          minimal tier:  always loaded
          server tier:   loaded when DOTFILES_PROFILE = server | develop
          develop tier:  loaded only when DOTFILES_PROFILE = develop
          │
          Each package file calls init_package_template, which either:
            (a) Tool installed  → run pkg_init
            (b) Tool missing    → print one-line warning, skip
            (c) VERBOSE=true    → run full install flow (install + init)
```

**Key invariant**: Installation never happens on normal shell startup.
`DOTFILES_VERBOSE=true` is the exclusive gate for all installation logic.

---

## Profile System

Profiles are **cumulative** — each tier includes all lower tiers:

| Profile   | Tiers loaded | Packages directory |
|-----------|-------------|-------------------|
| `minimal` | `minimal`   | `zsh/packages/minimal/` |
| `server`  | `minimal` + `server` | + `zsh/packages/server/` |
| `develop` | `minimal` + `server` + `develop` | + `zsh/packages/develop/` |

The profile is read from `$DOTFILES_PROFILE` at shell startup.
To switch: `dotfiles profile server` (persists to `~/.zshenv`), then `source ~/.zshrc`.

---

## Package System

### File Naming

```
zsh/packages/<tier>/<name>.zsh

tier — minimal | server | develop
name — tool name, lowercase, hyphens allowed (e.g. fzf, ripgrep, goenv)
```

Files within a tier directory load in **alphabetical order**.
If a package must load before others (e.g. sheldon must precede all other minimal packages),
name it with a leading character: `sheldon.zsh` loads before `tmux.zsh` alphabetically.

### Package Lifecycle API

```zsh
#!/usr/bin/env zsh

PKG_NAME="toolname"          # Used in all log messages and install prompts
PKG_DESC="Short description" # Shown when tool is not installed
PKG_CMD="toolname"           # Binary to check with `command -v` (defaults to PKG_NAME)
                             # Set to "" to use a custom check (see PKG_CHECK_FUNC)

# Custom existence check — use when the tool is not a standard binary (e.g. nvm)
# Must be a function name that returns 0 if installed, 1 if not
PKG_CHECK_FUNC=""

# Optional: runs before installation
pkg_pre_install() { }

# Optional: custom installer — overrides the OS package manager
# Use for tools not in standard repos (curl installers, git clone, etc.)
pkg_install() { }

# Optional: custom fallback for unsupported Linux distros
# Called when the detected distro has no known package manager
pkg_install_fallback() { }

# Optional: runs after successful first installation
pkg_post_install() { }

# Optional: runs on every shell start when the tool IS installed
# Keep this fast — it runs synchronously on every shell open
# Put lazy loading setup here, not in a separate *_lazy.zsh file
pkg_init() { }

init_package_template "$PKG_NAME"
```

**Rules:**
- All hook functions are optional — omit them if not needed
- `pkg_init` runs on every shell startup — keep it under 5ms (use lazy loading for slow tools)
- `pkg_install` fully overrides the default package manager — use it for custom install scripts
- `pkg_install_fallback` is the escape hatch for unknown Linux distros (FR-7)
- Do **not** create separate `*_lazy.zsh` files — put lazy loading inline in `pkg_init`

### Package Lifecycle Flow

```
init_package_template "pkgname"
  │
  ├── Check if tool is installed:
  │     PKG_CHECK_FUNC defined → call it
  │     otherwise              → command -v PKG_CMD
  │
  ├── Tool IS installed:
  │     → run pkg_init  (every shell start)
  │     → done
  │
  └── Tool NOT installed:
        DOTFILES_VERBOSE != true:
          → print: "[dotfiles] <name> not installed — run: dotfiles install"
          → done (non-blocking)
        DOTFILES_VERBOSE = true:
          → run pkg_pre_install (if defined)
          → run pkg_install (if defined)
              else: call platform installer
                    if distro unknown: call pkg_install_fallback (if defined)
                    else: print actionable error, return 1
          → verify install (re-run check)
          → run pkg_post_install (if defined)
          → run pkg_init
          → done
```

### Standard Package Example

```zsh
#!/usr/bin/env zsh

PKG_NAME="bat"
PKG_DESC="A cat clone with syntax highlighting and Git integration"

pkg_post_install() {
    # Ubuntu/Debian ships bat as 'batcat' — create a compat symlink
    [[ "$(uname -s)" == "Linux" ]] && ! command -v batcat &>/dev/null && \
        create_symlink "$(command -v bat)" "/usr/local/bin/batcat"
}

pkg_init() {
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
}

init_package_template "$PKG_NAME"
```

### Custom Installer + Lazy Loading Example (nvm)

```zsh
#!/usr/bin/env zsh

PKG_NAME="nvm"
PKG_DESC="Node Version Manager"
PKG_CMD=""
PKG_CHECK_FUNC="_nvm_is_installed"

_nvm_is_installed() {
    local dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -d "$dir" ]] && [[ -f "$dir/nvm.sh" ]]
}

pkg_install() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
}

pkg_init() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    export NVM_DIR="$nvm_dir"

    _lazy_load_nvm() {
        source "$NVM_DIR/nvm.sh"
    }

    create_lazy_wrapper "node" "_lazy_load_nvm" "npm" "npx" "yarn" "pnpm"
}

init_package_template "$PKG_NAME"
```

### Custom Distro Fallback Example

```zsh
#!/usr/bin/env zsh

PKG_NAME="fd"
PKG_DESC="A fast alternative to find"

pkg_install_fallback() {
    # Handles Alpine, NixOS, or any other unknown distro
    local version="10.1.0"
    local arch="$(uname -m)"
    curl -fsSL "https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-${arch}-unknown-linux-musl.tar.gz" \
        | tar -xz --strip-components=1 -C /usr/local/bin fd-*/fd
}

init_package_template "$PKG_NAME"
```

---

## Lazy Loading

Heavy tools (nvm, pyenv, goenv) take 100–500ms to initialize. Lazy loading defers this
cost until the first time a related command is actually used.

### How It Works

`create_lazy_wrapper "cmd" "load_func" [extra_cmds...]` registers shell functions that:

1. Intercept the first call to `cmd`
2. Run `load_func` (the real initialization)
3. Remove the wrapper function for `cmd` (the real binary takes over)
4. Re-invoke the original command with the original arguments

> **Note on extra_cmds**: The main `cmd` wrapper is removed after load.
> Wrappers for `extra_cmds` also call `load_func` on first use but are not removed —
> they become no-ops once the load function is idempotent.
> For correctness, lazy load functions must be safe to call multiple times.

### Timing Illustration

```zsh
# Shell startup — these are shell functions (wrappers), not real commands:
$ type node
node is a shell function

# First invocation — wrapper fires, nvm initializes (~200ms, once only):
$ node --version
v22.0.0

# All subsequent calls — real binary, no overhead:
$ type node
node is /Users/user/.nvm/versions/node/v22.0.0/bin/node
```

### Lazy Loader Pattern (inline in pkg_init)

```zsh
pkg_init() {
    export TOOL_ROOT="$HOME/.tool"
    export PATH="$TOOL_ROOT/bin:$PATH"

    _lazy_load_tool() {
        eval "$(tool init -)"        # or: source "$TOOL_ROOT/tool.sh"
    }

    [[ -d "$TOOL_ROOT" ]] && \
        create_lazy_wrapper "tool" "_lazy_load_tool" "tool-companion-cmd"
}
```

---

## Shared Libraries (`zsh/lib/`)

### `installer.zsh`

Sourced in `zshrc` before any package files. Provides:

| Function | Purpose |
|----------|---------|
| `init_package_template` | Package lifecycle orchestrator (check → warn/install → init) |
| `is_package_installed cmd` | Returns 0 if `cmd` is in PATH and executable |
| `_dotfiles_install_package name` | Delegates to the detected OS package manager |
| `_dotfiles_log_info/debug/warning/error/success msg` | Leveled logging (`error` always shown; others only when `VERBOSE=true`) |
| `ensure_directory path` | `mkdir -p` with error suppression |
| `copy_if_missing src dst` | Copies only if destination does not exist |
| `create_symlink target link` | `ln -sf` wrapper; skips if link already exists |

> **Important**: `is_package_installed` uses `command -v`. It does **not** work for
> shell-function-based tools (nvm, pyenv, goenv). Those must set `PKG_CHECK_FUNC`.

### `platform.zsh`

Sourced in `zshrc` before any package files. Provides:

| Function | Returns | Example |
|----------|---------|---------|
| `dotfiles_os` | `macos` \| `linux` \| `freebsd` \| `unknown` | `macos` |
| `dotfiles_distro` | Distro ID from `/etc/os-release` or `unknown` | `ubuntu` |
| `dotfiles_pkg_manager` | Package manager name or `unknown` | `brew` |

Used internally by `_dotfiles_install_package`. Package files can also call these
directly for platform-specific `pkg_post_install` logic.

### `lazy.zsh`

Sourced in `zshrc` before any package files. Provides:

| Function | Purpose |
|----------|---------|
| `create_lazy_wrapper cmd load_func [extras...]` | Register lazy-load wrappers for a command group |

---

## Plugin Management (Sheldon)

Zsh plugins are managed by [sheldon](https://sheldon.cli.rs).
Config lives at `config/sheldon/plugins.toml` (symlinked to `~/.config/sheldon/plugins.toml`).

Plugin load order:

| # | Plugin | Deferred? | Purpose |
|---|--------|-----------|---------|
| 1 | `zsh-defer` | No | Deferred loading utility |
| 2 | `fast-syntax-highlighting` | No | Command syntax highlighting |
| 3 | `zsh-completions` | **No** | Adds to `fpath` — must precede `compinit` |
| 4 | `fzf-tab` | Yes | fzf-powered tab completion UI |
| 5 | `zsh-autosuggestions` | Yes | Fish-style inline suggestions |
| 6 | `k` | Yes | Colorized directory listings |
| 7 | `ni` | Yes | Package manager detection |
| 8 | `zsh-nvm` | Yes | NVM integration |
| 9 | `powerlevel10k` | Yes | Prompt theme |

**`compinit` ordering**: `compinit` must run **after** `zsh-completions` adds its entries
to `fpath`. It is called in `sheldon.zsh`'s `pkg_init`, immediately after
`eval "$(sheldon source)"`. The `zsh/core/30-completion.zsh` file contains only
`zstyle` declarations — no `compinit` call.

---

## Symlink Management

`bin/dotfiles` manages two symlink categories:

| Source | Target | Example |
|--------|--------|---------|
| `$DOTFILES_ROOT/<file>` | `$HOME/.<file>` | `zshrc` → `~/.zshrc` |
| `$DOTFILES_ROOT/config/<tool>/` | `$HOME/.config/<tool>/` | `config/bat/` → `~/.config/bat/` |

Files excluded from symlinking:

```
README.md   CHANGELOG.md   CLAUDE.md
docs/       scripts/       bin/
.git/       .gitignore     *.zwc
```

**Conflict handling**: If a target path already exists and is not a symlink pointing to
this repo — the CLI prints a warning and skips it. It never overwrites. The `verify`
command surfaces all conflicts.

---

## Cross-Platform Notes

| Feature | macOS | Linux |
|---------|-------|-------|
| Package manager | Homebrew | apt / dnf / pacman / zypper |
| zsh availability | System-provided (5.9+) | Must install (`apt install zsh`) |
| `bat` binary name | `bat` | `bat` or `batcat` (handled in `pkg_post_install`) |
| pyenv build deps | Xcode CLT | `build-essential`, `libssl-dev`, `libbz2-dev`, etc. |
| nvm install | curl installer | curl installer |
| goenv install | `git clone` | `git clone` |
| yabai / skhd | Config files only | Not applicable |
| Unknown distro | n/a (brew covers all) | `pkg_install_fallback` (FR-7) |

---

## Debugging and Verification

```zsh
# Measure shell startup time (3-run average)
for i in 1 2 3; do time zsh -i -c exit; done

# See full install/init log for all packages
DOTFILES_VERBOSE=true zsh -i -c exit

# Force re-install a specific package
DOTFILES_VERBOSE=true DOTFILES_FORCE_INSTALL=true zsh -i -c exit

# Check symlink state
dotfiles verify

# See which packages have warnings (not installed)
zsh -i -c exit 2>&1 | grep '\[dotfiles\]'
```
