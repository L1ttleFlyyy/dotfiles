local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font: FiraCode Nerd Font with ligatures
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular" })
config.font_size = 12
config.harfbuzz_features = { "liga=1", "calt=1" }

-- Cursor
config.default_cursor_style = "BlinkingBar"

-- Default program
config.default_prog = { "pwsh" }

-- Color scheme: auto light/dark switching
local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Catppuccin Macchiato"
  else
    return "GruvboxLight"
  end
end

local scheme, appearance
if wezterm.gui then
  appearance = wezterm.gui.get_appearance()
  scheme = scheme_for_appearance(appearance)
else
  scheme = "Catppuccin Macchiato"
end
config.color_scheme = scheme

-- Tab bar: fancy style with scheme-matched colors
local is_dark = not appearance or appearance:find("Dark")

config.window_frame = {
  font = wezterm.font("FiraCode Nerd Font", { weight = "Bold" }),
  font_size = 11,
  active_titlebar_bg = is_dark and "#1e2030" or "#ebdbb2",
  inactive_titlebar_bg = is_dark and "#1e2030" or "#ebdbb2",
  active_titlebar_fg = is_dark and "#cad3f5" or "#3c3836",
  inactive_titlebar_fg = is_dark and "#6e738d" or "#928374",
}

config.colors = {
  tab_bar = {
    background = is_dark and "#1e2030" or "#ebdbb2",
    active_tab = {
      bg_color = is_dark and "#24273a" or "#fbf1c7",
      fg_color = is_dark and "#cad3f5" or "#3c3836",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = is_dark and "#1e2030" or "#ebdbb2",
      fg_color = is_dark and "#6e738d" or "#928374",
    },
    inactive_tab_hover = {
      bg_color = is_dark and "#363a4f" or "#d5c4a1",
      fg_color = is_dark and "#cad3f5" or "#3c3836",
    },
    new_tab = {
      bg_color = is_dark and "#1e2030" or "#ebdbb2",
      fg_color = is_dark and "#6e738d" or "#928374",
    },
    new_tab_hover = {
      bg_color = is_dark and "#363a4f" or "#d5c4a1",
      fg_color = is_dark and "#cad3f5" or "#3c3836",
    },
  },
}

-- Window: clean look, hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_close_confirmation = "NeverPrompt"
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }

-- Notifications: WezTerm natively supports OSC 9 and OSC 777
-- No extra config needed — enabled by default

-- Tab/window title: show process name, not full path
local function basename(path)
  return path:gsub("(.*[/\\])(.*)", "%2"):gsub("%.exe$", "")
end

wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local title = basename(pane.foreground_process_name or pane.title)
  if title == "" then title = "shell" end
  -- Center-pad to a fixed width so all tabs are uniform
  local width = 32
  if #title < width then
    local pad = width - #title
    local left = math.floor(pad / 2)
    title = string.rep(" ", left) .. title .. string.rep(" ", pad - left)
  end
  return " " .. title .. " "
end)

wezterm.on("format-window-title", function(tab)
  local pane = tab.active_pane
  return basename(pane.foreground_process_name or pane.title)
end)

local act = wezterm.action
if wezterm.target_triple:find("windows") then
  -- AutoHotkey owns the user-facing Left Alt namespace on Windows. These
  -- unreachable function keys are its action interface for operations without
  -- an equivalent default WezTerm shortcut.
  config.keys = {
    { key = "F13", mods = "NONE", action = act.QuitApplication },
    { key = "F14", mods = "NONE", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "F15", mods = "NONE", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "F16", mods = "NONE", action = act.CloseCurrentPane({ confirm = false }) },
    { key = "F17", mods = "NONE", action = act.ActivateTab(8) },
    { key = "F18", mods = "NONE", action = act.ActivateTabRelative(-1) },
    { key = "F19", mods = "NONE", action = act.ActivateTabRelative(1) },
  }
else
  -- Alt-leading shortcuts (macOS Cmd muscle memory)
  config.keys = {
  -- Copy / Paste
  { key = "c", mods = "ALT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "ALT", action = act.PasteFrom("Clipboard") },

  -- Tab management
  { key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "ALT", action = act.CloseCurrentTab({ confirm = true }) },

  -- Switch tabs: Alt-1 through Alt-9
  { key = "1", mods = "ALT", action = act.ActivateTab(0) },
  { key = "2", mods = "ALT", action = act.ActivateTab(1) },
  { key = "3", mods = "ALT", action = act.ActivateTab(2) },
  { key = "4", mods = "ALT", action = act.ActivateTab(3) },
  { key = "5", mods = "ALT", action = act.ActivateTab(4) },
  { key = "6", mods = "ALT", action = act.ActivateTab(5) },
  { key = "7", mods = "ALT", action = act.ActivateTab(6) },
  { key = "8", mods = "ALT", action = act.ActivateTab(7) },
  { key = "9", mods = "ALT", action = act.ActivateTab(8) },

  -- Word navigation: send Ctrl-Left/Right (works in most shells)
  { key = "LeftArrow", mods = "ALT", action = act.SendKey({ key = "LeftArrow", mods = "CTRL" }) },
  { key = "RightArrow", mods = "ALT", action = act.SendKey({ key = "RightArrow", mods = "CTRL" }) },

  -- Delete word backward / forward
  { key = "Backspace", mods = "ALT", action = act.SendKey({ key = "w", mods = "CTRL" }) },
  { key = "Delete", mods = "ALT", action = act.SendKey({ key = "Delete", mods = "CTRL" }) },

  -- Font size
  { key = "=", mods = "ALT", action = act.IncreaseFontSize },
  { key = "-", mods = "ALT", action = act.DecreaseFontSize },
  { key = "0", mods = "ALT", action = act.ResetFontSize },

  -- Find (search mode)
  { key = "f", mods = "ALT", action = act.Search("CurrentSelectionOrEmptyString") },

  -- New window
  { key = "n", mods = "ALT", action = act.SpawnWindow },

  -- Reload config
  { key = "r", mods = "ALT", action = act.ReloadConfiguration },

  -- Select all
  { key = "a", mods = "ALT", action = act.SendKey({ key = "a", mods = "CTRL" }) },

  -- Quit
  { key = "q", mods = "ALT", action = act.QuitApplication },

  -- Split panes
  { key = "\\", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "|", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Close pane (or tab if last pane)
  { key = "W", mods = "ALT|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

  -- Navigate panes (vim-style)
  { key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  }
end

return config
