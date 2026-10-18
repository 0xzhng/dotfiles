local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces, brackets, paddings = {}, {}, {}

for i = 1, 10 do
  local space = sbar.add("space", "space." .. i, {
    space = i, drawing = false, updates = true,
    script = "", click_script = "",
    icon = {
      font = { family = settings.font.text, style = settings.font.style_map["Heavy"] },
      string = i, padding_left = 15, padding_right = 8,
      color = colors.white, highlight_color = colors.orange,
    },
    label = {
      padding_right = 20, color = colors.white,
      highlight_color = colors.yellow,
      font = "sketchybar-app-font:Regular:16.0", y_offset = -1,
    },
    padding_right = 1, padding_left = 1,
    background = {
      color = colors.bar.bg, border_width = 2, height = 28,
      border_color = colors.black,
    },
  })
  spaces[i] = space
  local bracket = sbar.add("bracket", { space.name }, {
    drawing = false,
    background = {
      color = colors.transparent, border_color = colors.bg2,
      height = 30, border_width = 2,
    },
  })
  brackets[i] = bracket
  paddings[i] = sbar.add("space", "space.padding." .. i, {
    space = i, drawing = false, script = "", click_script = "",
    width = settings.group_paddings,
  })
  -- Display-only: no click handler, desktop switching, or preview popup.
  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon = { highlight = selected },
      label = { highlight = selected },
      background = { border_color = selected and colors.highlight or colors.bar.bg },
    })
    bracket:set({
      background = { border_color = selected and colors.grey or colors.bg2 },
    })
  end)
end

local observer = sbar.add("item", "spaces.observer", { drawing = false, updates = true })
observer:subscribe("space_windows_change", function(env)
  local sid = tonumber(env.INFO.space)
  if not spaces[sid] then return end
  local icon_line, occupied = "", false
  for app, count in pairs(env.INFO.apps) do
    if count > 0 then
      occupied = true
      icon_line = icon_line .. " " .. (app_icons[app] or app_icons["default"])
    end
  end
  spaces[sid]:set({ drawing = occupied, label = { string = icon_line, drawing = icon_line ~= "" } })
  brackets[sid]:set({ drawing = occupied })
  paddings[sid]:set({ drawing = occupied })
end)
