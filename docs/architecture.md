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

Current directory structure:

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
│   │   ├── 30-completion.zsh       # zstyle declarations only (compinit runs in 00-sheldon.zsh)
│   │   ├── 40-aliases.zsh          # Shell shortcuts (cd, reload); tool aliases live in packages
│   │   ├── 50-theme.zsh            # Powerlevel10k instant prompt + theme load
│   │   └── 60-zcompile.zsh         # Background .zwc bytecode compilation
│   │
│   ├── lib/                        # Shared libraries — sourced before packages
│   │   ├── installer.zsh           # Package lifecycle engine + logging + utilities
│   │   ├── lazy.zsh                # Lazy loading (create_lazy_wrapper)
│   │   └── platform.zsh            # OS/distro detection helpers
│   │
│   └── packages/                   # One .zsh file per tool, grouped by tier
│       ├── minimal/
│       │   ├── 00-sheldon.zsh      # Plugin manager — must load first (order prefix required)
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
  │       30-completion.zsh  — zstyle declarations ONLY (no compinit call here)
  │       40-aliases.zsh     — shell shortcuts (cd, reload); tool aliases live in packages
  │       50-theme.zsh       — Powerlevel10k instant prompt + p10k load
  │       60-zcompile.zsh    — background .zwc bytecode compilation
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

**Ordering contracts:**
- Within `minimal/`, `sheldon.zsh` loads before `tmux.zsh` by natural alphabetical order
  (`s` < `t`) — this is intentional but fragile. Any new package starting with `a`–`r`
  would load before sheldon, which breaks the plugin system.
- **Rule**: If a package has a strict load-order requirement, prefix its filename with a
  two-digit number: `00-sheldon.zsh` loads before everything else regardless of new additions.
- Non-ordered packages in `server/` and `develop/` can use plain names — they have no
  cross-dependencies and alphabetical order is acceptable.

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
- `pkg_install_fallback` is the escape hatch for unknown Linux distros
- Do **not** create separate `*_lazy.zsh` files — put lazy loading inline in `pkg_init`

**Hook function scope**: Each package file's hook functions (`pkg_init`, `pkg_install`, etc.)
are defined as global shell functions. They are **not automatically unset** after
`init_package_template` returns. The next package file's hooks overwrite the previous
definitions — this works correctly only because package files process sequentially.
Do not define hook functions outside package files, and do not rely on hooks from
a previously loaded package.

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
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    # Guard 1: don't re-register wrappers on source ~/.zshrc after nvm is loaded
    [[ "${_DOTFILES_NVM_LOADED:-}" == "1" ]] && return 0

    _lazy_load_nvm() {
        # Guard 2: npm/npx wrappers call this on every invocation — must be a no-op after load
        [[ "${_DOTFILES_NVM_LOADED:-}" == "1" ]] && return 0

        [[ -f "$NVM_DIR/nvm.sh" ]] || return 1
        source "$NVM_DIR/nvm.sh"
        [[ -f "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion" 2>/dev/null
        typeset -f nvm >/dev/null 2>&1 || return 1
        export _DOTFILES_NVM_LOADED="1"

        # Auto-install LTS if no Node version is installed
        if [[ -z "$(nvm list 2>/dev/null | grep -E 'v[0-9]+')" ]]; then
            nvm install --lts && nvm alias default 'lts/*' && nvm use --lts
        else
            nvm use default &>/dev/null || nvm use --lts &>/dev/null || nvm use node &>/dev/null
        fi
    }

    create_lazy_wrapper "nvm" "_lazy_load_nvm" "node" "npm" "npx"

    # yarn/pnpm: only wrap if not already available globally (outside nvm)
    command -v yarn &>/dev/null || create_lazy_wrapper "yarn" "_lazy_load_nvm"
    command -v pnpm &>/dev/null || create_lazy_wrapper "pnpm" "_lazy_load_nvm"
}

init_package_template "$PKG_NAME"
```

### Custom Distro Fallback Example

```zsh
#!/usr/bin/env zsh

PKG_NAME="fd"
PKG_DESC="A fast alternative to find"

pkg_install_fallback() {
    # Handles Alpine, NixOS, or any other unknown distro via prebuilt musl binary
    local version="10.1.0"
    local arch="$(uname -m)"
    local url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-${arch}-unknown-linux-musl.tar.gz"

    # Security: verify checksum before extracting
    local expected_sha="<sha256-of-the-tarball>"
    local tmpfile="$(mktemp)"
    curl -fsSL "$url" -o "$tmpfile"
    echo "${expected_sha}  ${tmpfile}" | sha256sum --check --quiet || {
        rm -f "$tmpfile"
        echo "[dotfiles] Checksum verification failed for fd" >&2
        return 1
    }
    tar -xz --strip-components=1 -C /usr/local/bin -f "$tmpfile" fd-*/fd
    rm -f "$tmpfile"
}

init_package_template "$PKG_NAME"
```

> **Security note**: Never use bare `curl | sh` or `curl | bash` in `pkg_install_fallback`.
> Always download to a temp file and verify a checksum before extracting or executing.
> For tools that provide signed releases, prefer GPG verification over SHA256.

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

> **Note on extra_cmds**: The main `cmd` wrapper is removed after load (real binary takes
> over). Wrappers for `extra_cmds` (e.g. `npm`, `pip`, `go`) are **not removed** — they
> remain as shell functions that call `load_func` on every invocation. After initialization,
> `load_func` returns immediately via its idempotency guard, so the overhead is one function
> call + flag check per invocation. This is acceptable but **both guards are required**:
>
> ```zsh
> pkg_init() {
>     # Guard 1: don't re-register wrappers on source ~/.zshrc after tool is loaded
>     [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0
>
>     _lazy_load_tool() {
>         # Guard 2: extra_cmd wrappers call this on every npm/go/pip invocation
>         [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0
>         ...
>         export _DOTFILES_TOOL_LOADED="1"
>     }
>
>     create_lazy_wrapper "tool" "_lazy_load_tool" "extra-cmd"
> }
> ```
>
> Without Guard 1: `source ~/.zshrc` after first use overwrites the real tool function with
> a lazy wrapper — tool silently stops working.
>
> Without Guard 2: `$PATH` grows with a duplicate entry on every `npm`/`go` invocation.

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

    # Guard 1: skip if already loaded (safe for source ~/.zshrc re-runs)
    [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0

    _lazy_load_tool() {
        # Guard 2: extra_cmd wrappers call this on every invocation — must be fast no-op
        [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0
        [[ -d "$TOOL_ROOT" ]] || return 1
        eval "$(tool init -)"        # or: source "$TOOL_ROOT/tool.sh"
        export _DOTFILES_TOOL_LOADED="1"
    }

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
| 8 | `powerlevel10k` | No | Prompt theme (loaded immediately) |

**`compinit` ordering**: `compinit` must run **after** `zsh-completions` adds its entries
to `fpath`. It is called in `00-sheldon.zsh`'s `pkg_init`, immediately after
`eval "$(sheldon source)"`. The `zsh/core/30-completion.zsh` file contains only
`zstyle` declarations — no `compinit` call.

**`.zcompdump` rebuild logic** (in `packages/minimal/00-sheldon.zsh`'s `pkg_init`):
```zsh
autoload -Uz compinit
# Rebuild the dump at most once per day; use cached otherwise
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit        # full rebuild
else
    compinit -C     # use cached dump, skip security check
fi
```
Do not remove this guard — rebuilding on every startup adds ~100ms.

---

## `bin/dotfiles` CLI Internals

The CLI is a Bash script. Each subcommand delegates to an internal function.

### `dotfiles install`

1. Sets `DOTFILES_VERBOSE=true` and sources `~/.zshrc` in a subshell
2. The package lifecycle runs for every package in the active profile
3. Any package not installed triggers the full install flow
4. Exits with 0 only if all packages initialize successfully

### `dotfiles update`

1. Checks `git status` — aborts with a warning if the working tree is dirty
2. Runs `git pull --ff-only origin $DOTFILES_BRANCH`
3. On success, runs `dotfiles install` to pick up new packages
4. On merge conflict or non-fast-forward: prints error and exits 1

### `dotfiles profile <name>`

1. Validates `<name>` is one of `minimal`, `server`, `develop`
2. Updates `DOTFILES_PROFILE=<name>` in `~/.zshenv`:
   - If the line already exists: replaces it with `sed -i`
   - If it does not exist: appends it
3. Prints: `Profile set to <name>. Run: source ~/.zshrc`

### `dotfiles verify`

Runs three checks and reports each finding:

| Check | Pass condition |
|-------|----------------|
| Symlink exists | `~/.zshrc` is a symlink |
| Symlink target | Symlink points into `$DOTFILES_ROOT` |
| Target file exists | The file at the symlink destination exists |

Also checks each package in the active profile and reports which are not installed.

### `dotfiles uninstall`

1. Removes all symlinks created by this repo (checks that each symlink points into `$DOTFILES_ROOT` before removing)
2. Removes `DOTFILES_ROOT`, `DOTFILES_PROFILE`, `DOTFILES_VERBOSE` lines from `~/.zshenv`
3. Does **not** uninstall packages installed by `dotfiles install` — those are left for the user to remove manually

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
this repo — the CLI removes it and creates the new symlink. The `verify` command checks
for broken symlinks after the fact.

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
# Measure shell startup time (3-run average, discard first)
for i in 1 2 3; do time zsh -i -c exit; done

# See full install/init log for all packages
DOTFILES_VERBOSE=true zsh -i -c exit

# Check symlink state
dotfiles verify

# See which packages have warnings (not installed)
zsh -i -c exit 2>&1 | grep '\[dotfiles\]'

# Debug lazy loading — check what type a command is before first use
type node    # → "node is a shell function" (wrapper registered)
node --version
type node    # → "node is /path/to/node" (real binary after lazy load)

# Force zcompdump rebuild (run after adding new completions)
rm -f ~/.zcompdump && exec zsh
```

---

## Migration: `zshrc.d/` → `zsh/` ✓ Complete

This migration was completed in two commits. The old `zshrc.d/` directory no longer
exists. The current `zsh/` layout is the canonical structure.

**What changed:**

| Old path | New path | Notes |
|----------|----------|-------|
| `zshrc.d/core/` | `zsh/core/` | Files renamed with hyphen separators |
| `zshrc.d/lib/install_helper.zsh` | `zsh/lib/installer.zsh` | + PKG_CHECK_FUNC, warnings, fallback |
| `zshrc.d/lib/lazy_load_wrapper.zsh` | `zsh/lib/lazy.zsh` | |
| _(new)_ | `zsh/lib/platform.zsh` | OS/distro detection (extracted from installer) |
| `zshrc.d/lib/*_lazy.zsh` | Inlined into package `pkg_init()` | No separate lazy files |
| `zshrc.d/lib/tmux_loader.zsh` | Inlined into `zsh/packages/minimal/tmux.zsh` | |
| `zshrc.d/pkg/100_m_sheldon.zsh` | `zsh/packages/minimal/00-sheldon.zsh` | Order prefix |
| `zshrc.d/pkg/*_m_*.zsh` | `zsh/packages/minimal/*.zsh` | |
| `zshrc.d/pkg/*_s_*.zsh` | `zsh/packages/server/*.zsh` | |
| `zshrc.d/pkg/*_d_*.zsh` | `zsh/packages/develop/*.zsh` | curlie removed |
