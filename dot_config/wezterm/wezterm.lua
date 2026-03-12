local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font: FiraCode Nerd Font with ligatures
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular" })
config.font_size = 16
config.harfbuzz_features = { "liga=1", "calt=1" }

-- Cursor
config.default_cursor_style = "BlinkingBar"

-- Color scheme: auto light/dark switching
local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Catppuccin Macchiato"
  else
    return "GruvboxLight"
  end
end

if wezterm.gui then
  config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
else
  config.color_scheme = "Catppuccin Macchiato"
end

-- Window: clean look, hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Notifications: WezTerm natively supports OSC 9 and OSC 777
-- No extra config needed — enabled by default

return config
