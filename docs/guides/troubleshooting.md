# Troubleshooting

## Startup is slow (> 200ms)

Measure with:
```zsh
for i in 1 2 3; do time zsh -i -c exit; done
```

Common causes:

| Symptom | Fix |
|---------|-----|
| Heavy tool runs at startup | Move initialization into `pkg_init` with lazy loading |
| `compinit` rebuilds every time | The `~/.zcompdump` guard in `00-sheldon.zsh` rebuilds at most once per day; if it still rebuilds, check that `~/.zcompdump` is writable |
| Slow git status in prompt | `POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096` limits dirty-check to repos < 4096 files; increase if needed |

## Tab completion not working

```zsh
# Force a full compinit rebuild
rm -f ~/.zcompdump && exec zsh
```

If that doesn't help, verify `zsh-completions` is loading before `compinit`:
```zsh
# Should show fpath includes zsh-completions
echo $fpath | tr ' ' '\n' | grep completions
```

The `compinit` call is in `zsh/packages/minimal/00-sheldon.zsh` and runs **after**
`eval "$(sheldon source)"`. If completion is broken after adding a new shell plugin,
check that the plugin adds to `fpath` before `compinit` runs.

## A command is not found after shell starts

Check if the package is installed:
```zsh
dotfiles verify
```

Check what type the command is (wrapper vs real binary):
```zsh
type nvm     # → "nvm is a shell function" means lazy wrapper is registered
nvm --version
type nvm     # → "nvm is /path/to/nvm" means real binary loaded
```

If the package shows as installed but `pkg_init` failed silently:
```zsh
# See all init output
DOTFILES_VERBOSE=true zsh -i -c exit 2>&1 | head -50
```

## Lazy loading not working

```zsh
# Before first use — should be a shell function
type python
# → python is a shell function from zsh/packages/develop/pyenv.zsh

# After first use — should be the real binary
python --version
type python
# → python is /Users/you/.pyenv/shims/python
```

If the real binary is still not found after first use:
1. Verify the tool is actually installed: `pyenv versions` / `nvm list`
2. Check that `pkg_init` sets PATH correctly before `create_lazy_wrapper`
3. For pyenv specifically: `pyenv install <version>` then `pyenv global <version>`

## Symlinks are broken

```zsh
dotfiles verify
# or check manually:
ls -la ~/.zshrc ~/.tmux.conf ~/.p10k.zsh
```

To recreate all symlinks:
```zsh
dotfiles link
```

## Profile not switching

```zsh
dotfiles profile server
source ~/.zshrc
echo $DOTFILES_PROFILE  # should be "server"
```

If the profile reverts after restarting zsh, check that `~/.zshenv` has the right value:
```zsh
grep DOTFILES_PROFILE ~/.zshenv
```

## `dotfiles install` fails on Linux

Check the detected package manager:
```zsh
zsh -c 'source ~/.dotfiles/zsh/lib/platform.zsh && dotfiles_pkg_manager'
```

For unknown distros, add a `pkg_install_fallback()` hook in the failing package file.
See `docs/guides/adding-a-package.md` for the fallback pattern.

## `.zwc` compiled files are stale

The background compiler (`zsh/core/60-zcompile.zsh`) runs at most once per 24h.
To force an immediate rebuild:
```zsh
rm -f ~/.cache/zsh/compile.stamp
exec zsh
```
