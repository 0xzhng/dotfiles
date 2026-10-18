local colors = require("colors")
local settings = require("settings")

sbar.add("item", "apple", {
  position = "left",
  icon = {
    string = "", color = colors.yellow,
    font = { family = settings.font.text, style = "Bold", size = 19 },
    padding_left = 8, padding_right = 8,
  },
  label = { drawing = false },
  background = { drawing = false, border_width = 0 },
  padding_left = 1, padding_right = 1,
  click_script = 'osascript "$CONFIG_DIR/plugins/apple_menu.applescript"',
})
sbar.add("item", { position = "left", width = settings.group_paddings })
