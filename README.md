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
When it's done, open a new terminal (restart Alacritty) to load PATH, fonts and profile.

It asks which profiles to enable, applies the dotfiles, then installs packages and plugins. The
OS is auto-detected: brew/apt on macOS/Linux, scoop (+ winget for PowerShell 7, as the MSI at the
fixed `C:\Program Files\PowerShell\7`) on Windows.
On Windows it also asks for the scoop and mise install dirs (default `~/.local/share/scoop`,
`~/.local/share/mise`; persisted as User `SCOOP` / `MISE_DATA_DIR`, shims put on PATH). An
existing scoop/mise elsewhere is kept, not moved.

## Profiles

| Profile | Default | Adds |
|---|---|---|
| base | always | zsh + powerlevel10k + sheldon (Unix) or PowerShell + starship (Windows), mise, Claude Code + plugins (incl. impeccable) |
| **tools** | on | CLI tools via mise (bat, eza, fd, ripgrep, fzf, micro, rtk, codegraph, agent-browser, agent-desktop, vivid, …), delta for git |
| **develop** | off | language runtimes via mise (`conf.d/develop.toml`: node, python, go, bun, pnpm, uv; Cloudflare's `cf` by hand: `pnpm add -g cf`) + Claude agent skills + agentmemory (Claude memory plugin + its server, started at login; need node) · Windows: scoop `make` (Linux: apt) |
| **apps** | off | essential GUI apps (`.chezmoidata.yaml` `appList`, essentials only — the rest by hand) · Windows: winget (Tailscale, Brave, Flow Launcher, ShareX, Windhawk) · macOS: brew casks (Tailscale, Brave) · Linux: vendor repos (Tailscale, Brave Origin) + apt Alacritty |
| **wm** | off (not Linux) | macOS: yabai + skhd · Windows: komorebi + whkd + yasb |
| **sshd** | off (Linux + Windows) | this box is an SSH server. Windows: scoop `no_junction` (+ a one-time `scoop reset *`) so scoop's shims work in an sshd session (it won't follow scoop's `current` junctions). Both OSes: keep Claude reachable across reboots (any other box with herdr: just run `herdr` after a reboot — it restores the layout and resumes every Claude pane): `herdr server` (holds the panes; after a restart resumes each Claude conversation, which re-attaches its Remote Control) + `claude remote-control` (start new sessions from claude.ai / the app, no SSH), both at boot — Linux: systemd user units + linger · Windows: logon tasks (needs autologon; the console is locked right after it). One-time: `claude auth login` and an interactive `claude remote-control` run |

Answers are stored in `~/.config/chezmoi/chezmoi.toml`. To change them:
`chezmoi init --prompt`, then `chezmoi apply`.

## Daily use

```sh
chezmoi edit ~/.zshrc        # edit a managed file
chezmoi apply                # apply; re-runs a bootstrap script if it changed
chezmoi update               # git pull + apply (installs what's missing; doesn't update anything)
chezmoi re-add ~/.zshrc      # capture a $HOME edit (not for .tmpl / modify_ targets)
chezmoi cd                   # open the source repo to commit/push
```

Shell aliases: `cz`, `cza`, `czd`, `czs`, `cze`, `czra`, `czu`, `czcd`; `..` / `...` / `....`, `lsal` (`ls -al`), `mkcd`, `reload`, `path`, `e` (editor), git `g` `gs` `gl` `gp` `gsw` `glg`, `cat` → bat without line numbers (plain text when piped), `top` → btm, `clc` / `clr` (claude --continue / --resume), `bp` (browser profile, below) — same on zsh and pwsh (+ `which` on pwsh).

- **Add a package:** CLI tools go in `dot_config/mise/conf.d/tools.toml.tmpl` (all OSes).
  OS packages go in `run_onchange_after_10-install-packages.{sh,ps1}.tmpl`.
- **Machine-local tools:** `mise use -g <tool>` writes to `~/.config/mise/config.toml`, which
  chezmoi ignores, so it survives `apply`.
- **Claude settings:** `~/.claude/settings.json` is merged with the tracked keys, so changes
  made in Claude Code survive `apply`. Copy a change into
  `.chezmoitemplates/claude-settings.json` to share it.
- **Browsers:** Zen = personal (Firefox-based, so no agent tool can drive it), Brave's default
  profile = your work, and one Brave user-data-dir per agent context or client in
  `~/.local/share/browser-profiles/<name>`. Agents use `agent-browser` (mise; launches Brave via the
  rendered `~/.agent-browser/config.json`, closes an idle headless browser after 15m; agents `close` a headed one); `bp <name>` opens a
  profile by hand, `bp` lists them. Profile dirs are machine-local — cookies are encrypted per OS
  user, so log in once per machine. Agents can't run page JS, download, upload or save/load cookies
  (`~/.agent-browser/policy.json`); moving a login is yours: set `AGENT_BROWSER_ENCRYPTION_KEY`
  (per machine, kept in your password manager) and run `agent-browser --action-policy <a looser policy file> state save` by hand (Claude is denied that flag).
- **Desktop apps:** agents use `agent-desktop` (mise) through the OS accessibility tree. It has no
  policy of its own, so every call goes through Claude's permission prompt and `~/.claude/CLAUDE.md`
  keeps it off terminals, browsers, password managers, mail/chat and system settings.
- **Claude permissions:** only read-only commands are auto-allowed (git/gh/mise read subcommands,
  `ls`, `wc`, `eza`, codegraph); everything else goes through auto mode's check. Secrets and browser
  data (`~/.ssh`, `.env*`, gh/Claude tokens, Brave/Zen/agent profiles) are denied to Read/Edit.
- **Terminal:** macOS = **Rex** (terminal + multiplexer, replaces Alacritty; installed from its
  appcast, self-updates; config `~/.config/rex/init.lua`). Windows + Linux = Alacritty, one config template
  `.chezmoitemplates/alacritty.toml` (applied to `~/.config/alacritty`; Windows' `%APPDATA%\alacritty` just
  imports it). Windows installs it via scoop (`scoop update alacritty`); Linux: apt, with the `apps` profile
  (needs >= 0.13 — Debian 12's is too old).
  Theme = the `[colors]` block (Catppuccin Mocha; fzf, bat, rg, starship, micro, vivid use
  ANSI colours only, so they follow any theme); JetBrainsMonoNL Nerd Font 14, copy-on-select,
  right-click pastes, `Ctrl+Enter` = Claude newline, Windows starts in `D:/work` (if it exists).
  Tabs/panes stay in herdr.
- **Secrets:** never commit them — use chezmoi `encrypted_` files or password-manager template
  functions.

## Windows notes

- The PowerShell profile (`~/.config/powershell/profile.ps1`) is dot-sourced from both pwsh 7
  and WinPS 5.1 `$PROFILE`s and loads in ~210ms (cached inits in `~/.cache/pwsh/v2`). Native output is decoded as UTF-8 (a Japanese-locale console is CP932).
- With fzf, PSFzf gives `Tab` completion, `Ctrl+t`, `Ctrl+r`, `Alt+c` (loaded on first use).
- `XDG_CONFIG_HOME=~/.config`, so tools read the same config tree as on Unix.
- `wm`: komorebi + whkd start at logon via komorebi's own autostart shortcut (no console flash); yasb via its own installer.
- Typing `powershell` in pwsh opens pwsh; WinPS 5.1 stays (an OS component chezmoi's bootstrap runs on).
- **pwsh 7 = one install, the MSI** at `C:\Program Files\PowerShell\7` (winget `--installer-type wix`,
  never the Store/MSIX one). Updates: patches (7.x.y) come through **Windows Update** (the MSI is
  opted into Microsoft Update); a new release line (7.x → 7.y) is
  `winget upgrade --id Microsoft.PowerShell --exact --installer-type wix --custom "USE_MU=1 ENABLE_MU=1"`.
  A Store/MSIX pwsh beside it shadows it and hides the MSI from `winget upgrade` — remove it from
  Windows PowerShell with every pwsh closed: `Get-AppxPackage Microsoft.PowerShell | Remove-AppxPackage`.
- Visual C++ 2015-2022 runtimes (x64 + x86) from winget, upgraded to the newest on every
  bootstrap run — the one step that shows a UAC prompt (a system-wide runtime).
- `gsudo` (scoop) for elevation; ssh = Windows' built-in OpenSSH (git uses it via `core.sshCommand`).
- SSH into the machine (`sshd` profile): scoop runs with `no_junction`, so its shims (git,
  starship…) work in an sshd session too (sshd won't follow scoop's `current` junctions).
- Claude Code finds scoop's Git Bash through
  `CLAUDE_CODE_GIT_BASH_PATH`; WinPS 5.1 gets `RemoteSigned` for CurrentUser (its default blocks scripts).
- Multiplexer = herdr (`herdr`); from another machine `herdr --remote <host>`.

## Layout

```
dot_zshrc, dot_p10k.zsh, dot_config/zsh/     # Unix shell
dot_config/powershell/, dot_config/starship.toml   # Windows shell
dot_config/mise/conf.d/                      # tools + runtimes (all OSes)
dot_config/                                  # other tool configs, gated per profile + OS
dot_local/bin/                               # helper scripts (Unix)
dot_claude/, .chezmoitemplates/              # Claude Code settings, CLAUDE.md, statuslines
.chezmoi.toml.tmpl, .chezmoiignore           # profile prompts, what applies where
run_onchange_after_10-install-packages.*     # bootstrap 1: OS packages, mise, wm
run_onchange_after_20-install-claude.*       # bootstrap 2: Claude Code, plugins, skills
```

Agent/contributor rules: `AGENTS.md`.
