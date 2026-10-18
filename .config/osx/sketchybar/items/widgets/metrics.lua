local colors = require("colors")
local settings = require("settings")

local metrics = {
  {
    name = "gpu", icon = "󰢮", color = colors.orange, size = 30, width = 30,
    command = [[ioreg -r -d 1 -c AGXAccelerator | awk -F'"Device Utilization %"=' 'NF>1 {split($2,a,","); gsub(/[^0-9]/,"",a[1]); print a[1]; exit}']],
  },
  {
    name = "cpu", icon = "", color = colors.yellow, size = 19, width = 24,
    command = [[top -l 2 -s 1 -n 0 | awk -F'[:,%]' '/CPU usage/ {u=$2+0; s=$4+0; found=1} END {if (found) printf "%.0f", u+s}']],
  },
}

for _, metric in ipairs(metrics) do
  local item = sbar.add("item", "widgets." .. metric.name, {
    position = "right",
    icon = { string = metric.icon, color = metric.color, width = metric.width, align = "center", y_offset = 0,
      font = { family = "JetBrainsMono Nerd Font Propo", style = "Regular", size = metric.size } },
    label = { string = "--", width = 40, color = colors.white },
    background = { drawing = false, border_width = 0 },
    padding_left = 3, padding_right = 3, update_freq = 5,
  })
  sbar.add("bracket", item.name .. ".bracket", { item.name }, {
    background = { color = colors.bar.bg, border_width = 2, border_color = colors.bg2 },
  })
  sbar.add("item", { position = "right", width = settings.group_paddings })
  local busy = false
  item:subscribe({ "routine", "forced", "system_woke" }, function()
    if busy then return end
    busy = true
    sbar.exec(metric.command, function(result, code)
      busy = false
      local value = code == 0 and tonumber(result) or nil
      if not value or value < 0 or value > 100 then
        item:set({ label = { string = "--", color = colors.grey } })
        return
      end
      local color = value >= 85 and colors.red or (value >= 70 and colors.orange or metric.color)
      item:set({ label = { string = string.format("%.0f%%", value), color = color } })
    end)
  end)
  item:subscribe("mouse.clicked", function()
    sbar.exec('osascript "$CONFIG_DIR/plugins/stats_menu.applescript" ' .. metric.name:upper())
  end)
end
