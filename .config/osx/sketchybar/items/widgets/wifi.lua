local colors = require("colors")
local settings = require("settings")
local stats = require("helpers.system_stats")

local upload = sbar.add("item", "widgets.wifi.upload", {
  position = "right", width = 0, y_offset = 5,
  padding_left = 0, padding_right = 0,
  icon = { drawing = false },
  label = {
    string = "--", width = 64, align = "right", color = colors.orange,
    font = { size = 9 }, padding_left = 0, padding_right = 6,
  },
})
local download = sbar.add("item", "widgets.wifi.download", {
  position = "right", y_offset = -5,
  padding_left = 0, padding_right = 0,
  icon = { drawing = false },
  label = {
    string = "--", width = 64, align = "right", color = colors.blue,
    font = { size = 9 }, padding_left = 0, padding_right = 6,
  },
})
local wifi = sbar.add("item", "widgets.wifi", {
  position = "right", width = 0, updates = true,
  icon = { drawing = false },
  label = { drawing = false },
  padding_left = 0, padding_right = 0, update_freq = 2,
})
sbar.add("bracket", wifi.name .. ".bracket", { wifi.name, upload.name, download.name }, {
  background = { color = colors.bar.bg },
})
sbar.add("item", { position = "right", width = settings.group_paddings })

local previous, busy
wifi:subscribe({ "routine", "forced", "wifi_change", "system_woke" }, function(env)
  if busy then return end
  if env.SENDER == "system_woke" or env.SENDER == "wifi_change" then previous = nil end
  busy = true
  -- Select the link row once; IPv4/IPv6 rows repeat the same counters.
  sbar.exec([[netstat -ibn -I en0 | awk '$3 ~ /^<Link#/ {print $7, $10; exit}']], function(result, code)
    busy = false
    local rx, tx = result:match("^(%d+)%s+(%d+)")
    rx, tx = tonumber(rx), tonumber(tx)
    local now = os.time()
    local up, down = "--", "--"
    if code == 0 and rx and tx then
      if previous and now > previous.time and rx >= previous.rx and tx >= previous.tx then
        up = stats.rate((tx - previous.tx) / (now - previous.time))
        down = stats.rate((rx - previous.rx) / (now - previous.time))
      end
      previous = { rx = rx, tx = tx, time = now }
    else
      previous = nil
    end
    upload:set({ label = up })
    download:set({ label = down })
  end)
end)
for _, item in ipairs({ wifi, upload, download }) do
  item:subscribe("mouse.clicked", function()
    sbar.exec("open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
  end)
end
