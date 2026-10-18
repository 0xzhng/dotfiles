local settings = require("settings")
local colors = require("colors")

local waller = sbar.add("item", "widgets.waller", {
  position = "left", drawing = false, updates = true, update_freq = 3,
  width = 28, padding_left = 3, padding_right = 3,
  icon = { drawing = false }, label = { drawing = false },
  background = {
    drawing = true, color = colors.transparent, border_width = 0,
    image = {
      string = "app.com.rynnzhng.waller", drawing = true, scale = 0.65,
      border_width = 0, corner_radius = 0,
    },
  },
  click_script = 'osascript "$CONFIG_DIR/plugins/waller_menu.applescript"',
})
local padding = sbar.add("item", "widgets.waller.padding", {
  position = "left", drawing = false, width = settings.group_paddings,
})

waller:subscribe({ "routine", "forced", "system_woke", "front_app_switched" }, function()
  sbar.exec("pgrep -x Waller >/dev/null", function(_, code)
    local running = code == 0
    waller:set({ drawing = running })
    padding:set({ drawing = running })
  end)
end)
