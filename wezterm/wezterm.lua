-- WezTerm config that mirrors kitty/kitty.conf: Catppuccin Frappé, Noto Sans Mono 10pt,
-- 75% opacity with blur, powerline tab bar at the bottom and the same shortcuts.
-- Works on Linux and Windows.
--
--   Linux:   ~/.config/wezterm/wezterm.lua   (install.sh links it)
--   Windows: %USERPROFILE%\.config\wezterm\wezterm.lua
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find('windows') ~= nil

-- Catppuccin Frappé, same values as kitty.conf
local c = {
  crust    = '#232634',
  mantle   = '#292C3C',
  base     = '#303446',
  overlay0 = '#737994',
  text     = '#C6D0F5',
  lavender = '#BABBF1',
  mauve    = '#CA9EE6',
  rosewater = '#F2D5CF',
}

-- Shell -------------------------------------------------------------------
-- Linux uses the login shell ($SHELL). Windows uses PowerShell 7.
if is_windows then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
end

-- Font --------------------------------------------------------------------
-- WezTerm ships the Nerd Font symbols as a built-in fallback, so prompt icons work without
-- installing a patched font.
config.font = wezterm.font 'Noto Sans Mono'
config.font_size = 10
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } -- disable_ligatures always

-- Cursor ------------------------------------------------------------------
config.default_cursor_style = 'BlinkingBar'
config.cursor_thickness = '1.5pt'
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Window ------------------------------------------------------------------
config.scrollback_lines = 2000
config.max_fps = 165 -- kitty: repaint_delay 6
config.window_background_opacity = 0.75
if is_windows then
  config.win32_system_backdrop = 'Acrylic'
else
  config.kde_window_background_blur = true -- KDE Plasma (Wayland or X11)
end
config.window_padding = { left = '1pt', right = '1pt', top = '1pt', bottom = '1pt' }
config.window_close_confirmation = 'NeverPrompt'
config.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 } -- kitty doesn't dim inactive splits
config.window_frame = {
  active_titlebar_bg = c.base, -- kitty: wayland_titlebar_color background
  inactive_titlebar_bg = c.base,
}

-- Colors ------------------------------------------------------------------
config.colors = {
  foreground = c.text,
  background = c.base,
  cursor_bg = c.rosewater,
  cursor_fg = c.base,
  cursor_border = c.rosewater,
  selection_fg = '#000010',
  selection_bg = '#6D9ECE',
  split = c.overlay0,
  ansi    = { '#51576D', '#E78284', '#A6D189', '#E5C890', '#8CAAEE', '#F4B8E4', '#81C8BE', '#B5BFE2' },
  brights = { '#626880', '#E78284', '#A6D189', '#E5C890', '#8CAAEE', '#F4B8E4', '#81C8BE', '#A5ADCE' },
  tab_bar = { background = c.crust },
}

-- Tab bar -----------------------------------------------------------------
-- kitty: tab_bar_edge bottom, tab_bar_style powerline, tab_bar_min_tabs 2
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

local POWERLINE = wezterm.nerdfonts.pl_left_hard_divider

local function tab_bg(tab)
  return tab.is_active and c.mauve or c.mantle
end

wezterm.on('format-tab-title', function(tab, tabs, _, _, _, max_width)
  -- Same as kitty's tab_title_template unless the tab was renamed with Alt+N
  local title = tab.tab_title
  if not title or title == '' then
    local n = #tab.panes
    title = n .. ' window' .. (n > 1 and 's' or '') .. ' opened'
  end
  title = wezterm.truncate_right(' ' .. title .. ' ', max_width - 1)

  local bg = tab_bg(tab)
  local next_tab = tabs[tab.tab_index + 2]
  return {
    { Background = { Color = bg } },
    { Foreground = { Color = tab.is_active and c.crust or c.text } },
    { Text = title },
    { Background = { Color = next_tab and tab_bg(next_tab) or c.crust } },
    { Foreground = { Color = bg } },
    { Text = POWERLINE },
  }
end)

-- Show when the Alt+R resize mode is active
wezterm.on('update-status', function(window)
  local mode = window:active_key_table()
  window:set_right_status(mode == 'resize_pane'
    and wezterm.format { { Foreground = { Color = c.lavender } }, { Text = ' RESIZE: w/n/t/s or arrows, Esc to exit ' } }
    or '')
end)

-- Shortcuts ---------------------------------------------------------------
-- kitty: clear_all_shortcuts yes, then only the maps below.
-- A kitty "window" is a WezTerm pane (split) and kitty's new_window/new_tab start in the home
-- directory, so these do too.
config.disable_default_key_bindings = true

-- kitty's auto-tiling layouts split along the longer side, so do the same
local new_split = wezterm.action_callback(function(window, pane)
  local d = pane:get_dimensions()
  local spawn = { domain = 'CurrentPaneDomain', cwd = wezterm.home_dir }
  if d.pixel_width > d.pixel_height then
    window:perform_action(act.SplitHorizontal(spawn), pane)
  else
    window:perform_action(act.SplitVertical(spawn), pane)
  end
end)

-- kitty: change_font_size all +2.0 (WezTerm's IncreaseFontSize scales by 10% instead)
local function font_step(delta)
  return wezterm.action_callback(function(window)
    local overrides = window:get_config_overrides() or {}
    overrides.font_size = (overrides.font_size or config.font_size) + delta
    window:set_config_overrides(overrides)
  end)
end

local font_reset = wezterm.action_callback(function(window)
  local overrides = window:get_config_overrides() or {}
  overrides.font_size = nil
  window:set_config_overrides(overrides)
end)

config.keys = {
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- Windows (panes)
  { key = 'Enter', mods = 'ALT', action = new_split },
  { key = 'w', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivatePaneDirection 'Next' },
  { key = 'Tab', mods = 'ALT', action = act.ActivatePaneDirection 'Prev' },
  { key = 'r', mods = 'ALT', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false } },
  -- kitty's next_layout cycles tall/fat/grid/stack/...; WezTerm has no layouts, so this
  -- toggles the closest one: zoom the current pane to fill the tab (kitty's "stack")
  { key = 'l', mods = 'ALT', action = act.TogglePaneZoomState },

  -- Tabs
  { key = 'RightArrow', mods = 'ALT', action = act.ActivateTabRelative(1) },
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = 't', mods = 'ALT', action = act.SpawnCommandInNewTab { domain = 'CurrentPaneDomain', cwd = wezterm.home_dir } },
  { key = 'q', mods = 'ALT', action = act.CloseCurrentTab { confirm = false } },
  { key = 'UpArrow', mods = 'ALT', action = act.MoveTabRelative(1) },
  { key = 'DownArrow', mods = 'ALT', action = act.MoveTabRelative(-1) },
  {
    key = 'n',
    mods = 'ALT',
    action = act.PromptInputLine {
      description = 'Tab title (empty to reset)',
      action = wezterm.action_callback(function(window, _, line)
        if line then window:active_tab():set_title(line) end
      end),
    },
  },

  -- Font size (numpad + and -)
  { key = 'Add', mods = 'ALT', action = font_step(2) },
  { key = 'Subtract', mods = 'ALT', action = font_step(-2) },
  { key = 'Backspace', mods = 'ALT', action = font_reset },

  { key = 'F5', mods = 'ALT', action = act.ReloadConfiguration },
}

-- Alt+R resize mode, same keys as kitty: w(ider) n(arrower) t(aller) s(horter).
-- Hold Ctrl for bigger steps. Esc or Enter leaves the mode.
local function resize(dir, n) return act.AdjustPaneSize { dir, n } end
config.key_tables = {
  resize_pane = {
    { key = 'w', action = resize('Right', 1) },
    { key = 'n', action = resize('Left', 1) },
    { key = 't', action = resize('Down', 1) },
    { key = 's', action = resize('Up', 1) },
    { key = 'w', mods = 'CTRL', action = resize('Right', 5) },
    { key = 'n', mods = 'CTRL', action = resize('Left', 5) },
    { key = 't', mods = 'CTRL', action = resize('Down', 5) },
    { key = 's', mods = 'CTRL', action = resize('Up', 5) },
    { key = 'RightArrow', action = resize('Right', 1) },
    { key = 'LeftArrow', action = resize('Left', 1) },
    { key = 'DownArrow', action = resize('Down', 1) },
    { key = 'UpArrow', action = resize('Up', 1) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },
  },
}

-- Mouse -------------------------------------------------------------------
-- kitty: copy_on_select yes, middle-click pastes the selection
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection',
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  {
    event = { Down = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = act.PasteFrom 'PrimarySelection',
  },
}

return config
