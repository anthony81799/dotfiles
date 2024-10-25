-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'FiraCode Nerd Font Mono',
  'Fira Code',
  'MesloLGS NF',
  'Droid Sans Mono',
  'monospace'
}
config.font_size = 18.0

config.color_scheme = 'GruvboxDarkHard'

config.window_background_opacity = 0.7
-- config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

config.window_decorations = "RESIZE"

-- and finally, return the configuration to wezterm
return config
