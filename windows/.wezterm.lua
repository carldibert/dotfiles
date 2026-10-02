-- WezTerm on Windows 11, matching the kitty setup (Catppuccin Frappé, Noto Sans Mono 10pt).
-- Copy to %USERPROFILE%\.wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_prog = { 'pwsh.exe', '-NoLogo' }
config.color_scheme = 'Catppuccin Frappe'
config.font = wezterm.font 'Noto Sans Mono'  -- WezTerm bundles the Nerd Font symbols as a fallback
config.font_size = 10
config.window_background_opacity = 0.75
-- config.win32_system_backdrop = 'Acrylic'  -- optional blur behind the window

return config
