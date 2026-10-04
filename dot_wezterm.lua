-- WezTerm: the one terminal on every OS. It only draws; tmux (Windows: psmux) keeps the
-- sessions, splits and restore, so WezTerm's own tabs/panes stay out of the way.
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Any Gogh theme ships built in as "<name> (Gogh)" (https://gogh-co.github.io/Gogh/).
-- Catppuccin Mocha matches the tmux pane backgrounds (window-active-style #1e1e2e); another
-- theme also needs those two bg colours in dot_tmux.conf.tmpl changed to match.
config.color_scheme = 'Catppuccin Mocha (Gogh)'

-- The family the bootstrap installs (scoop JetBrainsMono-NF / brew font-jetbrains-mono-nerd-font).
config.font = wezterm.font 'JetBrainsMonoNL Nerd Font'
config.font_size = 14

if wezterm.target_triple:find 'windows' then
  config.default_prog = { 'pwsh', '-NoLogo' }
end

config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = 'NeverPrompt'

-- Selecting copies (WezTerm's default); right-click pastes, as in Windows Terminal.
config.mouse_bindings = {
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = act.PasteFrom 'Clipboard' },
}

config.keys = {
  -- Claude's newline: Alt+Enter (ESC CR) is the one form psmux and SSH both pass through.
  { key = 'Enter', mods = 'CTRL', action = act.SendString '\x1b\r' },
}

return config
