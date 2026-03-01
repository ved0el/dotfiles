# CLAUDE.md — Dotfiles Development Guide

## Project Overview

A cross-platform, profile-based zsh configuration system. Ships on macOS and common Linux
distros. Keeps shell startup under 200ms by lazy-loading heavy tools.

Three cumulative profiles:

| Profile   | Tools added |
|-----------|-------------|
| `minimal` | tmux (+ sheldon infrastructure) |
| `server`  | bat, eza, fd, fzf, ripgrep, tealdeer, zoxide |
| `develop` | nvm, pyenv, goenv |

---

## Shell Language Rules

| Path | Language | Reason |
|------|----------|--------|
| `bin/dotfiles` | **Bash** | Runs before zsh is configured; must work on minimal systems |
| `zsh/**/*.zsh` | **Zsh** | Shell config; may use zsh-specific builtins (`typeset`, `zstyle`, glob qualifiers) |

Do **not** mix the two. Never use `#!/usr/bin/env zsh` in `bin/dotfiles`.

---

## Architecture

```
bin/dotfiles          Bash CLI — symlinks, install, update, profile switch
  │
zshrc                 Entry point (< 40 lines) — sources core/ + libs + packages
  │
  ├── zsh/core/       Always-loaded modules (setopt, history, completion, aliases, theme)
  ├── zsh/lib/        Shared libraries — installer, lazy loader, platform detection
  └── zsh/packages/   One file per tool, grouped by profile tier
```

Full details: `docs/architecture.md`
Requirements: `docs/requirements.md`
How to add a package: `docs/guides/adding-a-package.md`

---

## Adding a New Package

1. Pick the right tier: `minimal` | `server` | `develop`
2. Create **one file**: `zsh/packages/<tier>/<toolname>.zsh`
3. Do **not** modify `zshrc`, `installer.zsh`, or any other core file
4. Call `init_package_template "$PKG_NAME"` at the end

Minimal template:
```zsh
#!/usr/bin/env zsh

PKG_NAME="toolname"
PKG_DESC="One-line description"

pkg_init() {
    # runs every shell start — keep fast (< 5ms)
    alias t="toolname --flag"
}

init_package_template "$PKG_NAME"
```

---

## Naming Conventions

| Symbol | Convention | Example |
|--------|-----------|---------|
| Package variables | `PKG_NAME`, `PKG_DESC`, `PKG_CMD`, `PKG_CHECK_FUNC` | — |
| Hook functions | `pkg_init`, `pkg_install`, `pkg_pre_install`, `pkg_post_install`, `pkg_install_fallback` | — |
| Private helpers (check) | `_<tool>_is_installed` | `_nvm_is_installed` |
| Lazy loader function | `_lazy_load_<tool>` | `_lazy_load_nvm` |
| Load flag (idempotency) | `_DOTFILES_<TOOL>_LOADED` | `_DOTFILES_NVM_LOADED` |

---

## Idempotency Rules (Critical)

Shell startup must be **safe to run multiple times** (e.g. `source ~/.zshrc` after a tool
is already active). Two guards are required for every lazy-loaded version manager:

### Guard 1 — `pkg_init` entry guard
Prevents re-registering wrappers when `pkg_init` is called again:
```zsh
pkg_init() {
    export TOOL_ROOT="$HOME/.tool"
    [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0   # <-- required

    _lazy_load_tool() { ... }
    create_lazy_wrapper "tool" "_lazy_load_tool" "companion-cmd"
}
```

### Guard 2 — `_lazy_load_<tool>` entry guard
Prevents the extra_cmd wrappers (which persist after first load) from re-initializing:
```zsh
_lazy_load_tool() {
    [[ "${_DOTFILES_TOOL_LOADED:-}" == "1" ]] && return 0   # <-- required
    ...
    export _DOTFILES_TOOL_LOADED="1"
}
```

> Without Guard 1: `source ~/.zshrc` after first use overwrites the real tool function
> with a lazy wrapper → tool silently stops working.
>
> Without Guard 2: extra_cmd wrappers (`npm`, `pip`, `go`) re-run the initializer on
> every invocation → PATH keeps growing with duplicate entries.

---

## Testing

```zsh
# Measure shell startup time (3-run average, discard first)
time zsh -i -c exit

# Verify all symlinks and package installs
dotfiles verify

# Test a lazy loader works correctly
source ~/.zshrc
type node        # should say "node is a shell function"
node --version   # triggers lazy load
type node        # should say "node is /path/to/node"

# Re-source safety check (should produce no errors)
source ~/.zshrc
source ~/.zshrc
```

---

## Common Pitfalls

1. **Modifying core files** — Never add tool logic to `zshrc`, `installer.zsh`, or `zsh/core/*.zsh`.
   Each tool is self-contained in its own package file.

2. **Forgetting idempotency guards** — Every lazy-loaded version manager needs both guards
   (see above). Skipping them causes hard-to-debug re-source breakage.

3. **Making `pkg_init` slow** — `pkg_init` runs synchronously at shell startup. Anything
   over ~5ms must be deferred via `create_lazy_wrapper`.

4. **Using `command -v` for shell-function tools** — `nvm`, `pyenv`, `goenv` are not
   binaries. Set `PKG_CHECK_FUNC` to a custom function, or `command -v` will always fail.

5. **Adding a package that sorts before `00-sheldon.zsh`** — Files in `zsh/packages/minimal/`
   load alphabetically. Any new file starting with `a`–`n` would load before sheldon and
   break the plugin system. Prefix with a number (`00-`) if strict ordering is required.

6. **Bare `curl | bash` in `pkg_install_fallback`** — Always download to a temp file and
   verify a checksum before executing. See `docs/architecture.md` for the safe pattern.

---

## Key Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_ROOT` | `~/.dotfiles` | Path to this repo |
| `DOTFILES_PROFILE` | `minimal` | Active profile (set via `dotfiles profile <name>`) |
| `DOTFILES_VERBOSE` | `false` | Set to `true` to trigger install flow + verbose logging |
