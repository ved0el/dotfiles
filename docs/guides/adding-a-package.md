# Adding a Package

A package is a single `.zsh` file in `zsh/packages/<tier>/`. No other file needs to change.

## Step 1 — Choose the right tier

| Tier | Directory | When to use |
|------|-----------|-------------|
| `minimal` | `zsh/packages/minimal/` | Tools needed even on a bare server |
| `server` | `zsh/packages/server/` | Productivity tools for any dev/ops machine |
| `develop` | `zsh/packages/develop/` | Language runtimes and dev-only tools |

Profiles are cumulative: `develop` includes `server` which includes `minimal`.

## Step 2 — Create the package file

```
zsh/packages/<tier>/<toolname>.zsh
```

Filename rules: lowercase, hyphens allowed, no number prefix needed.

**Exception**: If your package must load before or after another package in the same
tier, prefix with a two-digit number: `00-sheldon.zsh` guarantees first load.

## Step 3 — Fill in the template

```zsh
#!/usr/bin/env zsh

PKG_NAME="toolname"          # Used in log messages and install prompts
PKG_DESC="Short description" # Shown when the tool is not installed
# PKG_CMD="toolname"         # Binary to check (defaults to PKG_NAME)
# PKG_CHECK_FUNC="_toolname_is_installed"  # Use for non-binary tools (nvm, pyenv)

# Optional: custom existence check (needed when the tool is not a binary)
# _toolname_is_installed() { [[ -d "$HOME/.toolname" ]]; }

# Optional: runs before the package manager
# pkg_pre_install() { }

# Optional: overrides the OS package manager entirely
# pkg_install() {
#     curl -fsSL https://example.com/install.sh | bash
# }

# Optional: fallback for unknown Linux distros
# pkg_install_fallback() {
#     local url="https://github.com/org/tool/releases/download/v1.0/tool-linux.tar.gz"
#     local tmpfile; tmpfile=$(mktemp)
#     curl -fsSL "$url" -o "$tmpfile"
#     # ALWAYS verify checksum before extracting
#     echo "abc123...  $tmpfile" | sha256sum --check --quiet || { rm -f "$tmpfile"; return 1; }
#     tar -xz -C /usr/local/bin -f "$tmpfile" tool
#     rm -f "$tmpfile"
# }

# Optional: runs after successful first installation
# pkg_post_install() { }

# Optional: runs on every shell start when the tool IS installed
pkg_init() {
    export TOOLNAME_OPTION="value"
    alias t="toolname"
}

init_package_template "$PKG_NAME"
```

## Step 4 — Test it

```zsh
# Verify it loads without errors
zsh -i -c 'type toolname' 2>/dev/null

# Simulate install mode
DOTFILES_VERBOSE=true zsh -c '
  source ~/.dotfiles/zsh/lib/platform.zsh
  source ~/.dotfiles/zsh/lib/installer.zsh
  source ~/.dotfiles/zsh/lib/lazy.zsh
  source ~/.dotfiles/zsh/packages/<tier>/toolname.zsh
'

# Check startup time impact (should stay under 200ms)
for i in 1 2 3; do time zsh -i -c exit; done
```

## Rules

- **All hook functions are optional** — only define what you need
- **`pkg_init` is synchronous** — keep it under 5ms; use lazy loading for slow tools
- **Put lazy loading inside `pkg_init`** — do not create separate `*_lazy.zsh` files
- **`PKG_CMD=""`** — set this when the tool is not a binary; pair with `PKG_CHECK_FUNC`
- **Never use `curl | sh`** — always download to a temp file and verify a checksum first

## Lazy loading example (for slow tools)

```zsh
pkg_init() {
    export TOOL_ROOT="$HOME/.tool"
    export PATH="$TOOL_ROOT/bin:$PATH"

    _lazy_load_tool() {
        # Idempotency guard — extra_cmds wrappers call this on every invocation
        typeset -f tool >/dev/null 2>&1 && return 0
        eval "$(tool init -)"
    }

    create_lazy_wrapper "tool" "_lazy_load_tool" "tool-subcmd"
}
```

See `zsh/packages/develop/nvm.zsh`, `pyenv.zsh`, and `goenv.zsh` for real examples.
