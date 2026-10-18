-- Run: cd ~/.config/sketchybar && lua tests/smoke.lua
package.path = "./?.lua;" .. package.path
local format = require("helpers.codex_usage").format
assert(format(nil) == "--")
assert(format({ error = "offline" }) == "--")
assert(format({ usage = { primary = { usedPercent = 20 }, secondary = { usedPercent = 7 } } }) == "80%")
assert(format({ usage = { secondary = { usedPercent = 7 } } }) == "93%")
assert(format({ usage = { primary = { usedPercent = 100 } } }) == "0%")
assert(format({ usage = { primary = { usedPercent = -1 } } }) == "--")
assert(format({ usage = { primary = { usedPercent = 101 } } }) == "--")

-- Exercise the actual shell collectors and their failure handling.
local items, callbacks, clicks = {}, {}, {}
sbar = {
  add = function(kind, name, args)
    if kind ~= "item" or type(name) ~= "string" then return {} end
    local item = { name = name }
    items[name] = item
    function item:set(value) self.last = value end
    function item:subscribe(events, callback)
      if type(events) == "table" then callbacks[self.name] = callback
      elseif events == "mouse.clicked" then clicks[self.name] = callback end
    end
    return item
  end,
  exec = function(command, callback)
    local pipe = assert(io.popen(command))
    local result = pipe:read("*a")
    local ok = pipe:close()
    callback(result, ok and 0 or 1)
  end,
}
require("items.widgets.metrics")
for name, callback in pairs(callbacks) do
  callback()
  local label = items[name].last.label.string
  assert(label:match("^%d+%%$"), name .. ": invalid collector output: " .. label)
  print(name .. " " .. label)
end
sbar.exec = function(_, callback) callback("", 1) end
for name, callback in pairs(callbacks) do
  callback()
  assert(items[name].last.label.string == "--")
end
for name, click in pairs(clicks) do
  local command
  sbar.exec = function(value) command = value end
  click()
  assert(command:find("stats_menu.applescript", 1, true))
  assert(command:match(name:match("%.([^.]+)$"):upper() .. "$"))
end
local power = require("helpers.battery")
local custom = "Battery Power:\n powermode 1\nAC Power:\n powermode 2\n"
assert(power.mode(custom, "Battery Power") == 1)
assert(power.mode(custom, "AC Power") == 2)
assert(power.mode("AC Power:\n powermode 0\n", "AC Power") == 0)
assert(power.mode("AC Power:\n lowpowermode 1\n", "AC Power") == 1)
assert(power.mode("AC Power:\n lowpowermode 0\n", "AC Power") == 0)
assert(power.mode("", "AC Power") == nil)
assert(power.mode(custom, "UPS Power") == nil)
assert(power.color(1) == 0xfffabd2f)
assert(power.color(0) == 0xffffffff)
assert(power.color(2) == 0xffb8bb26)
assert(power.color(nil) == 0xff928374)
local temperature = require("helpers.temperature").average
assert(temperature("[Tp00] 40\n[Tp04] 60\n[TB0T] 99") == 50)
assert(temperature("[Tp00] -1\n[Tp04] 200") == nil)
assert(temperature("") == nil)
local sensor = assert(io.popen('"/Applications/Stats.app/Contents/Resources/smc" list -t'))
local live_temp = temperature(sensor:read("*a"))
sensor:close()
assert(live_temp and live_temp > 0 and live_temp < 130)
print(string.format("CPU temperature: %.1f°C", live_temp))
print("Codex percentage, temperature sensors, CPU/GPU collectors, and failure states passed.")
dofile("tests/layout.lua")
