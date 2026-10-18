local colors = require("colors")
local settings = require("settings")
local temperature = sbar.add("item", "widgets.temperature", {
  position = "left", update_freq = 10,
  icon = { drawing = false },
  label = { string = "--", color = colors.white, padding_left = 8, padding_right = 8 },
  background = { drawing = false, border_width = 0 },
  padding_left = 1, padding_right = 1,
})
sbar.add("item", { position = "left", width = settings.group_paddings })

local busy = false
temperature:subscribe({ "routine", "forced", "system_woke" }, function()
  if busy then return end
  busy = true
  sbar.exec('"/Applications/Stats.app/Contents/Resources/smc" list -t 2>/dev/null', function(result, code)
    busy = false
    local value = code == 0 and require("helpers.temperature").average(result) or nil
    temperature:set({ label = {
      string = value and string.format("%.0f°C", value) or "--",
      color = value and value >= 90 and colors.red or colors.white,
    } })
  end)
end)
