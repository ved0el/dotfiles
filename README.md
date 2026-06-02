# dotfiles

My personal dotfiles + machine bootstrap, managed with [chezmoi](https://chezmoi.io).
One command on a fresh machine syncs my config **and** installs the software and
plugins it depends on.

## Quick start (new machine)

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ved0el
```

This installs chezmoi, clones this repo, asks which profiles to enable, applies the
dotfiles, then installs packages + plugins. That's it — the machine is set up.

## Profiles

Profiles are toggled per machine at `init` time (stored in
`~/.config/chezmoi/chezmoi.toml`) and gate which files apply via `.chezmoiignore`.

| Profile     | When                 | Contents                                                                                       |
| ----------- | -------------------- | ---------------------------------------------------------------------------------------------- |
| **base**    | always               | zsh (+ powerlevel10k, sheldon), tmux (+ TPM plugins), mise, nano, Claude config; `git`, `tmux` |
| **tools**   | prompt (default on)  | bat, fd, ripgrep, zsh tool aliases, mise tool set; `btop`, `tree`                              |
| **develop** | prompt (default off) | language runtimes via mise (`conf.d/develop.toml`)                                             |
| **macos**   | auto (Darwin only)   | skhd, yabai                                                                                    |

Re-run the prompts any time:

```sh
chezmoi init --data=false    # re-ask the profile questions, then
chezmoi apply
```

## Daily use

```sh
chezmoi edit ~/.tmux.conf    # edit a managed file in $EDITOR
chezmoi apply                # apply changes + re-run bootstrap if it changed
chezmoi update               # git pull, then apply (sync from another machine)
chezmoi cd                   # drop into the source repo to commit/push
chezmoi add ~/.config/foo    # start managing a new file
chezmoi managed              # list everything chezmoi tracks
```

## Add a package

Edit `run_onchange_after_install-packages.sh.tmpl`, add the package to the right
branch, then `chezmoi apply` — the script re-runs automatically because its content
changed.

## Secrets

Never commit raw secrets. Use chezmoi's `encrypted_` files (age/gpg) or template
functions like `{{ onepasswordRead "op://..." }}` / `{{ (bitwarden ...) }}` for any
file that contains keys or tokens.

## Layout

```
dot_zshrc, dot_tmux.conf, dot_p10k.zsh        # ~/.zshrc, ~/.tmux.conf, ~/.p10k.zsh
dot_claude/                                   # ~/.claude/
dot_config/                                   # ~/.config/  (gated per profile)
.chezmoi.toml.tmpl                            # profile prompts -> machine data
.chezmoiignore                                # which files apply on this machine
run_onchange_after_install-packages.sh.tmpl   # packages + plugins bootstrap
```
