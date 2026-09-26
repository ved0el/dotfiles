# dotfiles

My dotfiles + machine bootstrap, managed with [chezmoi](https://chezmoi.io). One command on a
fresh machine applies the config **and** installs the software and plugins it needs.

## Quick start

```sh
# macOS / Linux
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply ved0el
```

```powershell
# Windows (PowerShell)
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$HOME/.local/bin'"; chezmoi init --apply ved0el
```

It asks which profiles to enable, applies the dotfiles, then installs packages and plugins. The
OS is auto-detected: brew/apt on macOS/Linux, scoop (+ winget for PowerShell 7) on Windows.

## Profiles

| Profile | Default | Adds |
|---|---|---|
| base | always | zsh + powerlevel10k + sheldon (Unix) or PowerShell + starship (Windows), mise, Claude Code + plugins + agent skills (skills need **develop** for node) |
| **tools** | on | CLI tools via mise (bat, eza, fd, ripgrep, fzf, micro, rtk, codegraph, vivid, …), delta for git |
| **develop** | off | language runtimes via mise (`conf.d/develop.toml`) |
| **tmux** | on (not Windows) | tmux + TPM plugins |
| **wm** | off (not Linux) | macOS: yabai + skhd · Windows: komorebi + whkd + yasb |

Answers are stored in `~/.config/chezmoi/chezmoi.toml`. To change them:
`chezmoi init --prompt`, then `chezmoi apply`.

## Daily use

```sh
chezmoi edit ~/.tmux.conf    # edit a managed file
chezmoi apply                # apply; re-runs a bootstrap script if it changed
chezmoi update               # git pull + apply; the only command that updates Claude plugins
chezmoi re-add ~/.tmux.conf  # capture a $HOME edit (not for .tmpl / modify_ targets)
chezmoi cd                   # open the source repo to commit/push
```

Shell aliases: `cz`, `cza`, `czd`, `czs`, `cze`, `czra`, `czu`, `czcd`.

- **Add a package:** CLI tools go in `dot_config/mise/conf.d/tools.toml.tmpl` (all OSes).
  OS packages go in `run_onchange_after_10-install-packages.{sh,ps1}.tmpl`.
- **Machine-local tools:** `mise use -g <tool>` writes to `~/.config/mise/config.toml`, which
  chezmoi ignores, so it survives `apply`.
- **Claude settings:** `~/.claude/settings.json` is merged with the tracked keys, so changes
  made in Claude Code survive `apply`. Copy a change into
  `.chezmoitemplates/claude-settings.json` to share it.
- **Secrets:** never commit them — use chezmoi `encrypted_` files or password-manager template
  functions.

## Windows notes

- The PowerShell profile (`~/.config/powershell/profile.ps1`) is dot-sourced from both pwsh 7
  and WinPS 5.1 `$PROFILE`s and loads in ~210ms (cached inits in `~/.cache/pwsh`).
- With fzf, PSFzf gives `Tab` completion, `Ctrl+t`, `Ctrl+r`, `Alt+c` (loaded on first use).
- `XDG_CONFIG_HOME=~/.config`, so tools read the same config tree as on Unix.
- `wm`: komorebi starts at logon via a scheduled task; yasb via its own installer.

## Layout

```
dot_zshrc, dot_p10k.zsh, dot_config/zsh/     # Unix shell
dot_config/powershell/, dot_config/starship.toml   # Windows shell
dot_config/mise/conf.d/                      # tools + runtimes (all OSes)
dot_config/                                  # other tool configs, gated per profile + OS
dot_tmux.conf, dot_local/bin/                # tmux (Unix)
dot_claude/, .chezmoitemplates/              # Claude Code settings, CLAUDE.md, statuslines
.chezmoi.toml.tmpl, .chezmoiignore           # profile prompts, what applies where
run_onchange_after_10-install-packages.*     # bootstrap 1: OS packages, mise, wm
run_onchange_after_20-install-claude.*       # bootstrap 2: Claude Code, plugins, skills
run_after_update-claude-plugins.*            # plugin refresh (`chezmoi update` only)
```

Agent/contributor rules: `AGENTS.md`.
