local colors = require("colors")
local settings = require("settings")
local stats = require("helpers.system_stats")

local allocated = sbar.add("item", "widgets.ram.allocated", {
  position = "right", width = 0, y_offset = 5,
  background = { drawing = false, border_width = 0 },
  padding_left = 0, padding_right = 0,
  icon = { drawing = false },
  label = {
    string = "--", width = 58, align = "right", color = colors.white,
    padding_left = 0, padding_right = 6, font = { size = 9 },
  },
})
local free = sbar.add("item", "widgets.ram.free", {
  position = "right", y_offset = -5,
  background = { drawing = false, border_width = 0 },
  padding_left = 0, padding_right = 0,
  icon = { drawing = false },
  label = {
    string = "--", width = 58, align = "right", color = colors.grey,
    padding_left = 0, padding_right = 6, font = { size = 9 },
  },
})
local ram = sbar.add("item", "widgets.ram", {
  position = "right", update_freq = 5,
  padding_left = 3, padding_right = 0,
  icon = { string = "􀧖", color = colors.yellow, width = 24, align = "center", y_offset = 0,
    font = { family = "SF Pro", style = "Bold", size = 18 } },
  label = { drawing = false },
  background = { drawing = false, border_width = 0 },
})
sbar.add("bracket", ram.name .. ".bracket", { ram.name, allocated.name, free.name }, {
  background = { color = colors.bar.bg, border_width = 2, border_color = colors.bg2 },
})
sbar.add("item", { position = "right", width = settings.group_paddings })

ram:subscribe({ "routine", "forced", "system_woke" }, function()
  sbar.exec("sysctl -n hw.memsize && vm_stat", function(result, code)
    local used, available
    if code == 0 then used, available = stats.memory(result) end
    allocated:set({ label = used and string.format("%.2f GB", used / 1024^3) or "--" })
    free:set({ label = available and string.format("%.2f GB", available / 1024^3) or "--" })
  end)
end)
for _, item in ipairs({ ram, allocated, free }) do
  item:subscribe("mouse.clicked", function()
    sbar.exec('osascript "$CONFIG_DIR/plugins/stats_menu.applescript" RAM')
  end)
end
