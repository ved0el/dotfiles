# Alacritty (Windows + Linux; macOS uses Rex)

Nested rules (the root AGENTS.md points here). Same style: terse; the why is in the commit.

- **Alacritty = the terminal** (picked for speed over WezTerm). Windows: scoop `extras/alacritty`,
  guarded on the command. macOS: NOT installed — Rex replaces it (`.config/alacritty` ignored there). Linux: apt `alacritty` under the `apps` profile (headless
  boxes skip it); warns when apt's is < 0.13 (Debian 12 = 0.11, YAML only); its font = Nerd Fonts'
  `JetBrainsMono.tar.xz` into `~/.local/share/fonts` (no apt package), guarded on the .ttf. One template
  `.chezmoitemplates/alacritty.toml` → `dot_config/alacritty/` on Windows + Linux (one path shared with
  other tools); Windows reads only `%APPDATA%`, never XDG, so `AppData/Roaming/alacritty/` is a stub
  whose `general.import` loads `~/.config/alacritty/alacritty.toml` (`.chezmoiignore` drops it on Unix). It only draws —
  sessions, splits and restore stay in herdr (it has no tabs; never bind `C-b`). Theme = the
  inline `[colors]` block (Catppuccin Mocha); tmux sets NO pane bg (`window-(active-)style`) so
  every pane uses the theme's bg (fzf too: `bg:` unset, `bg+:-1`). Dim (SGR 2) is darkened by
  Alacritty itself — no font trick. Windows start dir `D:/work` renders only when it exists
  (`stat`). Its font family must be one the bootstrap installs (macOS: cask
  `font-jetbrains-mono-nerd-font`, guarded on the .ttf).
