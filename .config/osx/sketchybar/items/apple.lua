local colors = require("colors")
local settings = require("settings")

local apple = sbar.add("item", "apple", {
  position = "left",
  icon = {
    string = "", color = colors.yellow,
    font = { family = settings.font.text, style = "Bold", size = 19 },
    padding_left = 8, padding_right = 8,
  },
  label = { drawing = false },
  background = { drawing = false, border_width = 0 },
  padding_left = 1, padding_right = 1,
  popup = { drawing = false, align = "left", horizontal = false, height = 32, y_offset = 4 },
})
sbar.add("item", { position = "left", width = settings.group_paddings })

local function close_menu()
  apple:set({ popup = { drawing = false } })
end

apple:subscribe("mouse.clicked", function()
  apple:set({ popup = { drawing = "toggle" } })
end)
apple:subscribe({ "mouse.exited", "mouse.exited.global", "front_app_switched", "system_woke" }, close_menu)

for _, entry in ipairs({
  { "about", "About This Mac" },
  { "settings", "System Settings…" },
  { "lock", "Lock Screen" },
  { "sleep", "Sleep" },
  { "restart", "Restart…" },
  { "shutdown", "Shut Down…" },
}) do
  local action = entry[1]
  local row = sbar.add("item", "apple." .. action, {
    position = "popup.apple",
    width = 228,
    padding_left = 5, padding_right = 5,
    icon = { drawing = false },
    label = {
      string = entry[2], color = colors.white,
      font = { family = settings.font.text, style = "Regular", size = 13 },
      padding_left = 12, padding_right = 12,
    },
    background = {
      drawing = true, color = colors.transparent,
      border_width = 0, height = 28, corner_radius = 5,
    },
  })
  row:subscribe("mouse.entered", function()
    row:set({ background = { color = colors.bg2 } })
  end)
  row:subscribe("mouse.exited", function()
    row:set({ background = { color = colors.transparent } })
  end)
  row:subscribe("mouse.clicked", function()
    close_menu()
    row:set({ background = { color = colors.transparent } })
    sbar.exec('osascript "$CONFIG_DIR/plugins/apple_menu.applescript" ' .. action)
  end)
end
