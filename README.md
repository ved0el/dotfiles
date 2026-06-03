# dotfiles

My personal dotfiles + machine bootstrap, managed with [chezmoi](https://chezmoi.io).
One command on a fresh machine syncs my config **and** installs the software and
plugins it depends on.

## Quick start (new machine)

**macOS / Linux** (installs chezmoi to `~/.local/bin`):

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply ved0el
```

**Windows** (PowerShell — installs chezmoi to `~\.local\bin`):

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$HOME/.local/bin'"; chezmoi init --apply ved0el
```

This installs chezmoi, clones this repo, asks which profiles to enable, applies the
dotfiles, then installs packages + plugins. That's it — the machine is set up.

The OS is auto-detected (`.chezmoi.os`), so there's no OS prompt: macOS/Linux bootstrap
with **brew/apt**, Windows with **scoop**. On Windows the tmux/zsh/sheldon stack is
skipped (tmux isn't even prompted) and a PowerShell profile is used instead — see
[Windows](#windows) below.

## Profiles

Profiles are toggled per machine at `init` time (stored in
`~/.config/chezmoi/chezmoi.toml`) and gate which files apply via `.chezmoiignore`.

| Profile     | When                 | Contents                                                                                       |
| ----------- | -------------------- | ---------------------------------------------------------------------------------------------- |
| **base**    | always               | zsh (+ powerlevel10k, sheldon), tmux (+ TPM plugins), mise, nano, Claude config; `git`, `tmux` |
| **tools**   | prompt (default on)  | mise tool set (bat, eza, fd, ripgrep, bottom, sd, fzf, …) + zsh/pwsh aliases (incl. `tree`→eza) |
| **develop** | prompt (default off) | language runtimes via mise (`conf.d/develop.toml`)                                             |
| **macos**   | auto (Darwin only)   | mole (cleanup CLI); yabai + skhd via **wm**                                                     |
| **windows** | auto (Windows only)  | scoop + mise + PowerShell profile; tmux/zsh/sheldon skipped                                     |
| **wm**      | prompt (default off) | macOS: yabai + skhd · Windows: komorebi + whkd + yasb                                           |

Re-run the prompts any time:

```sh
chezmoi init --data=false    # re-ask the profile questions, then
chezmoi apply
```

## Windows

Windows is gated off `.chezmoi.os == "windows"` (no extra prompt). Differences from
macOS/Linux:

- **Package manager:** [scoop](https://scoop.sh) (installed per-user, never elevated)
  instead of brew/apt. `git`, `pwsh`, and `mise` come from scoop; the CLI tool set
  (`bat`, `fd`, `ripgrep`, …) still comes from **mise** using the same
  `conf.d/{tools,develop}.toml` manifests.
- **Shell:** a managed `~/.config/powershell/profile.ps1` mirrors the zsh config
  (mise env injection, eza/zoxide/fzf wiring, chezmoi aliases). The bootstrap dot-sources
  it from your real `$PROFILE` for both PowerShell 7 and Windows PowerShell 5.1, so it
  survives OneDrive-redirected Documents.
- **`XDG_CONFIG_HOME`** is set to `~/.config` so mise and friends read the same config
  tree as Unix (mise would otherwise look in `%APPDATA%`).
- **Window manager** (`wm` profile, default off): scoop installs `komorebi`, `whkd`, and
  `yasb` — the Windows counterpart of macOS yabai/skhd. whkd/komorebi configs are managed
  under `~/.config`; start it with `komorebic start --whkd`.
- **Skipped:** tmux, sheldon, powerlevel10k, nano.

mise installs the tool set with `--yes`; pin or trim `conf.d/tools.toml` if a tool
lacks a Windows build. Cross-platform tools use prebuilt backends (e.g.
`aqua:eza-community/eza`) so they don't compile from source on Windows. Windows-only
mise tools live in `conf.d/windows.toml` (e.g. starship).

### Machine-local tools (not synced)

`mise use -g <tool>` writes to `~/.config/mise/config.toml`, which chezmoi **ignores**
(`MISE_GLOBAL_CONFIG_FILE` points there). Use it for per-machine tools you don't want in
the repo — they survive `chezmoi apply` untouched. Tools you want everywhere go in the
tracked `conf.d/*.toml` instead.

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

Edit the bootstrap for the OS family — `run_onchange_after_install-packages.sh.tmpl`
(macOS/Linux) or `run_onchange_after_install-packages.ps1.tmpl` (Windows) — add the
package to the right branch, then `chezmoi apply`. The script re-runs automatically
because its content changed. Cross-platform CLI tools go in `conf.d/tools.toml`
(mise) instead, so they install everywhere from one list.

## Secrets

Never commit raw secrets. Use chezmoi's `encrypted_` files (age/gpg) or template
functions like `{{ onepasswordRead "op://..." }}` / `{{ (bitwarden ...) }}` for any
file that contains keys or tokens.

## Layout

```
dot_zshrc, dot_tmux.conf, dot_p10k.zsh        # ~/.zshrc, ~/.tmux.conf, ~/.p10k.zsh  (Unix)
dot_config/powershell/profile.ps1             # ~/.config/powershell/profile.ps1     (Windows)
dot_claude/                                   # ~/.claude/
dot_config/                                   # ~/.config/  (gated per profile + OS)
.chezmoi.toml.tmpl                            # profile prompts + per-OS data/interpreters
.chezmoiignore                                # which files apply on this machine
run_onchange_after_install-packages.sh.tmpl   # macOS/Linux bootstrap (brew/apt + mise)
run_onchange_after_install-packages.ps1.tmpl  # Windows bootstrap (scoop + mise)
```
