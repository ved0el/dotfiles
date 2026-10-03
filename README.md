# dotfiles

My dotfiles + machine bootstrap, managed with [chezmoi](https://chezmoi.io). One command on a
fresh machine applies the config **and** installs the software and plugins it needs.

## Quick start

Copy the line for your OS into a terminal and press Enter.

**macOS / Linux** (Terminal):

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply ved0el
```

**Windows** (PowerShell — a normal window, **not** "Run as administrator"; the built-in
Windows PowerShell is fine on a new machine):

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; $b = "$HOME\.local\bin"; iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$b'"; $p = [Environment]::GetEnvironmentVariable('Path', 'User'); if (($p -split ';') -notcontains $b) { [Environment]::SetEnvironmentVariable('Path', "$b;$p", 'User') }; $env:Path = "$b;$env:Path"; chezmoi init --apply --keep-going ved0el
```

What the Windows line does, in order: enables TLS 1.2 (older Windows 10 defaults to TLS 1.0),
installs chezmoi into `~/.local/bin`, puts that dir on PATH (persisted once, and for this
window, so `chezmoi` works right away), then runs `chezmoi init --apply --keep-going`
(`--keep-going`: a failed bootstrap part doesn't skip the other). Safe to paste again.

Windows: a step that fails (network, GitHub rate limit, …) is reported in red at the end and
the bootstrap exits non-zero, so the next `chezmoi apply` retries only what's missing — fix and
re-run until it's clean. It stops up front, before changing anything, when run as administrator
or when winget isn't ready yet (a new account: update "App Installer" in Microsoft Store). Hit the
GitHub rate limit? `gh auth login` (gh is a mise tool) or set `GITHUB_TOKEN`, then `chezmoi apply`.
When it's done, open a new terminal (restart Windows Terminal) to load PATH, fonts and profile.

It asks which profiles to enable, applies the dotfiles, then installs packages and plugins. The
OS is auto-detected: brew/apt on macOS/Linux, scoop (+ winget for PowerShell 7) on Windows.
On Windows it also asks for the scoop and mise install dirs (default `~/.local/share/scoop`,
`~/.local/share/mise`; persisted as User `SCOOP` / `MISE_DATA_DIR`, shims put on PATH). An
existing scoop/mise elsewhere is kept, not moved.

## Profiles

| Profile | Default | Adds |
|---|---|---|
| base | always | zsh + powerlevel10k + sheldon (Unix) or PowerShell + starship (Windows), mise, Claude Code + plugins |
| **tools** | on | CLI tools via mise (bat, eza, fd, ripgrep, fzf, micro, rtk, codegraph, vivid, …), delta for git |
| **develop** | off | language runtimes via mise (`conf.d/develop.toml`: node, python, go, bun, pnpm, uv, `npm:cf`) + Claude agent skills (need node) |
| **tmux** | on | tmux + TPM plugins · Windows: psmux (same `~/.tmux.conf`, `tmux` works) + psmux-plugins |
| **wm** | off (not Linux) | macOS: yabai + skhd · Windows: komorebi + whkd + yasb |

Answers are stored in `~/.config/chezmoi/chezmoi.toml`. To change them:
`chezmoi init --prompt`, then `chezmoi apply`.

## Daily use

```sh
chezmoi edit ~/.tmux.conf    # edit a managed file
chezmoi apply                # apply; re-runs a bootstrap script if it changed
chezmoi update               # git pull + apply (installs what's missing; doesn't update anything)
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
- Windows Terminal: 2 profiles (pwsh, cmd), Catppuccin schemes (Mocha default), JetBrainsMonoNL
  Nerd Font 14, copy-on-select (selecting text copies it; right-click pastes) — merged into the live `settings.json`, so changes made in WT's UI survive `apply`.
- Typing `powershell` in pwsh opens pwsh; WinPS 5.1 stays (an OS component chezmoi's bootstrap runs on).
- Visual C++ 2015-2022 runtimes (x64 + x86) from winget, upgraded to the newest on every
  bootstrap run — the one step that shows a UAC prompt (a system-wide runtime).
- `gsudo` (scoop) for elevation; ssh = Windows' built-in OpenSSH (git uses it via `core.sshCommand`).
- Claude Code finds scoop's Git Bash through
  `CLAUDE_CODE_GIT_BASH_PATH`; WinPS 5.1 gets `RemoteSigned` for CurrentUser (its default blocks scripts).
- psmux: same keys as tmux. Not ported: `C-a f` (sessionizer); status shows the login user.

## Layout

```
dot_zshrc, dot_p10k.zsh, dot_config/zsh/     # Unix shell
dot_config/powershell/, dot_config/starship.toml   # Windows shell
dot_config/mise/conf.d/                      # tools + runtimes (all OSes)
dot_config/                                  # other tool configs, gated per profile + OS
dot_tmux.conf.tmpl, dot_local/bin/           # tmux (Unix) / psmux (Windows)
AppData/…/WindowsTerminal…/LocalState/       # Windows Terminal settings (merged)
dot_claude/, .chezmoitemplates/              # Claude Code settings, CLAUDE.md, statuslines
.chezmoi.toml.tmpl, .chezmoiignore           # profile prompts, what applies where
run_onchange_after_10-install-packages.*     # bootstrap 1: OS packages, mise, wm
run_onchange_after_20-install-claude.*       # bootstrap 2: Claude Code, plugins, skills
```

Agent/contributor rules: `AGENTS.md`.
