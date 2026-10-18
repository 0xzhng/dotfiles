local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local power = require("helpers.battery")

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  icon = { string = icons.battery._100, color = colors.grey },
  label = { string = "--", width = 40, color = colors.grey },
  background = { drawing = false, border_width = 0 },
  padding_left = 3, padding_right = 3, update_freq = 5,
})
sbar.add("bracket", battery.name .. ".bracket", { battery.name }, {
  background = { color = colors.bar.bg, border_width = 2, border_color = colors.bg2 },
})
sbar.add("item", { position = "right", width = settings.group_paddings })

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, function()
  sbar.exec("pmset -g batt && pmset -g custom", function(result, code)
    local value = code == 0 and tonumber(result:match("(%d+)%%")) or nil
    if not value then battery:set({ label = "--" }); return end
    local charging = result:find("; charging;", 1, true) ~= nil
    local icon = icons.battery._100
    if charging then icon = icons.battery.charging
    elseif value <= 10 then icon = icons.battery._0
    elseif value <= 25 then icon = icons.battery._25
    elseif value <= 50 then icon = icons.battery._50
    elseif value <= 75 then icon = icons.battery._75 end
    local source = result:match("Now drawing from '([^']+)'")
    local color = power.color(power.mode(result, source))
    battery:set({ icon = { string = icon, color = color }, label = { string = value .. "%", color = color } })
  end)
end)
battery:subscribe("mouse.clicked", function()
  sbar.exec("open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'")
end)
