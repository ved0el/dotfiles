-- WezTerm: the one terminal on every OS. It only draws; tmux (Windows: psmux) keeps the
-- sessions, splits and restore, so WezTerm's own tabs/panes stay out of the way.
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Any Gogh theme ships built in as "<name> (Gogh)" (https://gogh-co.github.io/Gogh/).
-- tmux sets no pane bg, so any theme works as-is.
config.color_scheme = 'Catppuccin Mocha (Gogh)'

-- The family the bootstrap installs (scoop JetBrainsMono-NF / brew font-jetbrains-mono-nerd-font).
config.font = wezterm.font 'JetBrainsMonoNL Nerd Font'
-- Dim (SGR 2) text: WezTerm's default rule draws it in ExtraLight, which reads hair-thin (mise's
-- `mise` prefix, hints). Keep Regular weight; the colour is still dimmed.
config.font_rules = {
  { intensity = 'Half', italic = true,
    font = wezterm.font('JetBrainsMonoNL Nerd Font', { weight = 'Regular', italic = true }) },
  { intensity = 'Half', italic = false,
    font = wezterm.font('JetBrainsMonoNL Nerd Font', { weight = 'Regular' }) },
}
config.font_size = 14

if wezterm.target_triple:find 'windows' then
  config.default_prog = { 'pwsh', '-NoLogo' }
end

-- GPU renderer on the discrete card (WebGpu is the default front_end; OpenGL draws thinner glyphs).
config.webgpu_power_preference = 'HighPerformance'

config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = 'NeverPrompt'

-- Selecting copies (WezTerm's default; hold Shift in an app that grabs the mouse); right-click pastes.
config.mouse_bindings = {
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = act.PasteFrom 'Clipboard' },
}

config.keys = {
  -- Claude's newline: Alt+Enter (ESC CR) is the one form psmux and SSH both pass through.
  { key = 'Enter', mods = 'CTRL', action = act.SendString '\x1b\r' },
}

-- Machine-local tweaks (unmanaged): ~/.wezterm.local.lua returns function(config).
local local_file = wezterm.home_dir .. '/.wezterm.local.lua'
local f = io.open(local_file, 'r')
if f then
  f:close()
  wezterm.add_to_config_reload_watch_list(local_file)
  dofile(local_file)(config)
end

return config
