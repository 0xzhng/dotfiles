local settings = require("settings")
local colors = require("colors")

sbar.add("item", { position = "right", width = settings.group_paddings })
local clock = sbar.add("item", "clock", {
  position = "right",
  icon = { drawing = false },
  label = { color = colors.white, padding_left = 10, padding_right = 10 },
  background = { color = colors.bar.bg, border_width = 2 },
  padding_left = 1, padding_right = 1,
  update_freq = 15,
})
sbar.add("bracket", "clock.bracket", { clock.name }, {
  background = { color = colors.transparent, height = 26, border_color = colors.bg2 },
})
sbar.add("item", { position = "right", width = settings.group_paddings })

clock:subscribe({ "forced", "routine", "system_woke" }, function()
  -- Stock-style date and 12-hour time with AM/PM.
  clock:set({ label = os.date("%a %e  %I:%M %p"):gsub("  +", "  ") })
end)
