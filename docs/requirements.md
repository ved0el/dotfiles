# Requirements

## Project Goals

A cross-platform, profile-based zsh configuration system that:

- Starts fast — lazy loading keeps shell startup under 200ms
- Works identically on macOS and common Linux distros
- Scales from a minimal server setup to a full development environment
- Warns clearly when a managed tool is missing, without blocking startup
- Is easy to extend with new tools without touching any core file

## Non-Goals

- GUI / desktop environment configuration (yabai/skhd configs are included as
  static files only, not managed as packages)
- Fish or Bash shell support — zsh only
- Package version pinning or lockfiles
- Remote secrets or credential management

---

## Functional Requirements

### FR-1: Profile System

The system must support three cumulative profiles:

| Profile   | Tier | User-facing tools |
|-----------|------|-------------------|
| `minimal` | `m`  | tmux |
| `server`  | `s`  | minimal + bat, fzf, eza, fd, ripgrep, tealdeer, zoxide |
| `develop` | `d`  | server + nvm, pyenv, goenv |

> **Note**: `sheldon` (zsh plugin manager) is a **core infrastructure dependency**, not a
> user-facing tool. It is installed as part of the bootstrap process and loaded before any
> profile package. It does not appear in the tier table because it is always required.

- Each profile includes all tools from lower tiers (cumulative, not exclusive)
- The active profile is set via `DOTFILES_PROFILE` environment variable
- Profile switches must persist across shell restarts — the CLI must update `DOTFILES_PROFILE`
  in `~/.zshenv` so the new profile is active on the next shell open
- Switching profiles must not require re-installation — only `source ~/.zshrc`

### FR-2: Package System

Each tool must be defined as a self-contained package file under `zsh/packages/<tier>/`.

A package file must be able to:
- Declare a custom installer (`pkg_install`) when the tool is not in standard repos
- Declare post-install setup steps (`pkg_post_install`)
- Declare runtime initialization (`pkg_init`) that runs on every shell start
- Define a custom existence check for tools that are not standard binaries (e.g. nvm)

**Installation behavior:**
- Installation only runs when `DOTFILES_VERBOSE=true` (i.e. during explicit `dotfiles install`)
- On normal shell startup, if a managed package is **not installed**, the system must print
  a one-line warning so the user knows what to run:
  ```
  [dotfiles] bat not installed — run: dotfiles install
  ```
- The warning must not block startup or print a stack trace

### FR-3: Lazy Loading

Tools with slow startup time (nvm, pyenv, goenv) must be lazy-loaded:

- Shell wrappers intercept the **first invocation** of the tool's commands
- On first use, the real tool initializes and all wrappers are replaced by real commands
- Subsequent calls incur zero overhead — the real binary is called directly

Commands wrapped per tool:

| Tool  | Commands always wrapped | Commands conditionally wrapped |
|-------|------------------------|-------------------------------|
| nvm   | `node`, `npm`, `npx`   | `yarn`, `pnpm` — only if found inside the nvm shims path |
| pyenv | `python`, `python3`, `pip`, `pip3` | — |
| goenv | `go`, `gofmt` | — |

> **Why `yarn`/`pnpm` are conditional**: These tools can be installed globally (outside nvm).
> Wrapping them unconditionally would intercept global installs and break them silently.
> Only wrap if their resolved path is inside `$NVM_DIR`.

### FR-4: Symlink Management

The `bin/dotfiles` CLI must manage symlinks from the dotfiles repo into `$HOME`:

- Root-level config files → `$HOME/.<filename>` (e.g. `zshrc` → `~/.zshrc`)
- `config/` subtree → `$HOME/.config/<tool>/` (e.g. `config/bat/` → `~/.config/bat/`)
- If a target already exists and is **not** a symlink to this repo: warn and skip, never overwrite
- The `verify` command must report all broken, missing, or conflicting links

### FR-5: Cross-Platform Package Installation

The package installer must auto-detect the OS and use the correct package manager:

| Platform | Package Manager | Detection |
|----------|-----------------|-----------|
| macOS | Homebrew (`brew`) | `uname -s == Darwin` |
| Ubuntu / Debian | `apt` | `ID=ubuntu\|debian` or `ID_LIKE` contains `debian` |
| Fedora / RHEL / Rocky / Alma | `dnf`, then `yum` | `ID=fedora\|centos\|rhel\|rocky\|alma` or `ID_LIKE` contains `rhel\|fedora` |
| Arch / Manjaro | `pacman` | `ID=arch\|manjaro\|endeavouros` or `ID_LIKE` contains `arch` |
| openSUSE | `zypper` | `ID=opensuse\|suse` or `ID_LIKE` contains `suse` |
| FreeBSD | `pkg` | `uname -s == FreeBSD` |
| **Other / unknown** | Custom fallback | see below |

Detection must check **both** `ID` and `ID_LIKE` from `/etc/os-release`. `ID_LIKE` is a
space-separated list of parent distros and must be matched as a substring.
This covers derivatives like Raspberry Pi OS (`ID=raspbian`, `ID_LIKE=debian`),
Linux Mint (`ID=linuxmint`, `ID_LIKE=ubuntu`), and Pop!_OS (`ID=pop`, `ID_LIKE=ubuntu`).

**Unknown distro handling** — when no package manager is matched:
1. Attempt `pkg_install_fallback()` if the package file defines it
2. If no fallback is defined, print a clear actionable error:
   ```
   [dotfiles] Cannot auto-install <tool> on <distro>. Install manually, then re-run.
   ```
3. Never silently skip — the user must know installation did not complete

Package files can define a fallback for unknown distros:

```zsh
pkg_install_fallback() {
    # Prefer verifying checksums over blind curl | sh
    local version="10.1.0"
    local archive="fd-v${version}-$(uname -m)-unknown-linux-musl.tar.gz"
    local url="https://github.com/sharkdp/fd/releases/download/v${version}/${archive}"
    curl -fsSL "$url" | tar -xz --strip-components=1 -C /usr/local/bin fd-*/fd
}
```

### FR-6: CLI (`bin/dotfiles`)

The `bin/dotfiles` command must support these subcommands:

| Command | Description |
|---------|-------------|
| `dotfiles install` | Install packages for the current profile |
| `dotfiles update` | Pull latest from git (`--ff-only`), re-run install |
| `dotfiles uninstall` | Remove all managed symlinks and reset `~/.zshenv` entries |
| `dotfiles profile <name>` | Switch active profile and persist to `~/.zshenv` |
| `dotfiles verify` | Report broken/missing symlinks and uninstalled packages |

**`dotfiles update` behavior on local changes:**
- Uses `git pull --ff-only` — fast-forward only, no merge commits
- If local changes exist (`git status` is dirty): print a warning and abort
  ```
  [dotfiles] Local changes detected. Commit or stash them before updating.
  ```
- Never auto-stashes or auto-resets — user owns their local changes

---

## Non-Functional Requirements

### NFR-1: Startup Performance

- Shell startup must complete in **< 200ms** on a 2020+ laptop with SSD
  (reference: M1 MacBook Pro or equivalent Intel/AMD machine with 8GB+ RAM)
- Measured with: `time zsh -i -c exit` (3-run average, discard first)
- Heavy tools (nvm, pyenv, goenv) must not block startup (use lazy loading)
- `compinit` must run only once per day (cached via `~/.zcompdump`)

### NFR-2: Portability

- All zsh code must be compatible with **zsh 5.8+**
- No reliance on GNU-specific flags — use POSIX-compatible alternatives where possible
- macOS and Linux behavior must be functionally equivalent for all `m` and `s` tier packages

### NFR-3: Idempotency

- Running `dotfiles install` multiple times must produce the same result
- Re-sourcing `~/.zshrc` must not produce errors or duplicate environment state
- Package init functions must be safe to call more than once:
  - `export PATH=...` prepends are acceptable only if guarded against duplicates
  - `create_lazy_wrapper` must check whether a wrapper already exists before registering
  - If a tool is already initialized (real binary in PATH), `pkg_init` must not re-wrap it

### NFR-4: Failure Isolation

- A failing package must not prevent other packages from loading
- Errors during `pkg_init` must be caught and logged; the next package must still load
- During install mode (`DOTFILES_VERBOSE=true`), full error context must be shown
- During normal startup, only the one-line warning (FR-2) is shown — no stack traces

### NFR-5: Extensibility

- Adding a new package requires creating **exactly one file** in `zsh/packages/<tier>/`
- No core file (`zshrc`, `zsh/lib/installer.zsh`, `zsh/core/*.zsh`) needs modification
- Package files may only depend on functions from `zsh/lib/installer.zsh`,
  `zsh/lib/lazy.zsh`, and `zsh/lib/platform.zsh`

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_ROOT` | `~/.dotfiles` | Absolute path to the dotfiles repo |
| `DOTFILES_PROFILE` | `minimal` | Active profile: `minimal`, `server`, or `develop` |
| `DOTFILES_VERBOSE` | `false` | Enable install logging and trigger installation flow |
| `DOTFILES_BRANCH` | `main` | Git branch used by `dotfiles update` |

---

## Constraints

- `zshrc` (entry point) must remain **< 40 lines** — logic lives in `zsh/`
- Package files must be self-contained, depending only on the three `zsh/lib/` files
- No global shell state mutation outside of standard `export` and `alias` calls
- `bin/dotfiles` is **Bash**; all files under `zsh/` are **zsh**
- Lazy loader logic must live **inside the package file's `pkg_init()`**, not in separate files
