local stats = require("helpers.system_stats")
local fixture = [[409600
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages active: 30.
Pages inactive: 20.
Pages speculative: 5.
Pages wired down: 10.
Pages occupied by compressor: 8.
Pages purgeable: 3.
File-backed pages: 20.
]]
local used, free = stats.memory(fixture)
assert(used == 204800 and free == 204800)
assert(stats.memory("") == nil)
assert(stats.memory(fixture:gsub("Pages active: 30.", "")) == nil)
assert(stats.memory(fixture:gsub("Pages active: 30.", "Pages active: 300.")) == nil)
assert(stats.rate(0) == "0 B/s")
assert(stats.rate(1024) == "1.0 KB/s")
assert(stats.rate(1024^2) == "1.0 MB/s")
assert(stats.rate(1024^3) == "1.0 GB/s")

local items, listeners, serial = {}, {}, 0
sbar = {
  add = function(kind, name, properties)
    local members = kind == "bracket" and name or nil
    if type(name) ~= "string" then
      properties = properties or name
      serial = serial + 1
      name = "test." .. serial
    end
    local item = { name = name, properties = properties or {}, members = members }
    items[name] = item
    function item:set(values)
      for key, value in pairs(values) do self.properties[key] = value end
    end
    function item:subscribe(events, callback)
      if type(events) == "string" then events = { events } end
      for _, event in ipairs(events) do
        listeners[event] = listeners[event] or {}
        listeners[event][self.name] = callback
      end
    end
    return item
  end,
}
require("items.spaces")
local observer = next(listeners.space_windows_change)
local update_space = listeners.space_windows_change[observer]
assert(items["space.5"].properties.drawing == false)
update_space({ INFO = { space = 5, apps = { Ghostty = 1 } } })
assert(items["space.5"].properties.drawing == true)
assert(items["space.5"].properties.label.string == " :ghostty:")
assert(items["space.5"].properties.label.drawing == true)
assert(items["space.padding.5"].properties.drawing == true)
for _, item in pairs(items) do
  if item.members and item.members[1] == "space.5" then
    assert(item.properties.drawing == true)
  end
end
update_space({ INFO = { space = 5, apps = { Ghostty = 0 } } })
assert(items["space.5"].properties.drawing == false)
assert(items["space.padding.5"].properties.drawing == false)
for _, item in pairs(items) do
  if item.members and item.members[1] == "space.5" then
    assert(item.properties.drawing == false)
  end
end
update_space({ INFO = { space = 20, apps = {} } })
for i = 1, 10 do
  local name = "space." .. i
  assert(items[name].properties.click_script == "")
  assert(not listeners["mouse.clicked"] or not listeners["mouse.clicked"][name])
end

local now, response, status = 100, "10000 2000", 0
local real_time = os.time
os.time = function() return now end
sbar.exec = function(command, callback)
  if command:find("netstat", 1, true) then callback(response, status)
  else callback("10.0.0.1", 0) end
end
require("items.widgets.wifi")
assert(items["widgets.wifi"].properties.icon.drawing == false)
assert(items["widgets.wifi"].properties.width == 0)
assert(items["widgets.wifi.upload"].properties.icon.drawing == false)
assert(items["widgets.wifi.download"].properties.icon.drawing == false)
local update_wifi = listeners.routine["widgets.wifi"]
update_wifi({ SENDER = "forced" })
assert(items["widgets.wifi.upload"].properties.label == "--")
now, response = 102, "12048 3024"
update_wifi({ SENDER = "routine" })
assert(items["widgets.wifi.upload"].properties.label == "512 B/s")
assert(items["widgets.wifi.download"].properties.label == "1.0 KB/s")
now, response = 104, "1 1"
update_wifi({ SENDER = "routine" })
assert(items["widgets.wifi.upload"].properties.label == "--")
now, response, status = 106, "", 1
update_wifi({ SENDER = "routine" })
assert(items["widgets.wifi.download"].properties.label == "--")
os.time = real_time

sbar.exec = function(_, callback) callback(fixture, 0) end
require("items.widgets.ram")
listeners.routine["widgets.ram"]()
assert(items["widgets.ram.allocated"].properties.label == string.format("%.2f GB", used / 1024^3))
assert(items["widgets.ram.free"].properties.label == string.format("%.2f GB", free / 1024^3))
sbar.exec = function(_, callback) callback("", 1) end
listeners.routine["widgets.ram"]()
assert(items["widgets.ram.allocated"].properties.label == "--")
assert(items["widgets.ram.free"].properties.label == "--")
for _, name in ipairs({ "widgets.ram", "widgets.ram.allocated", "widgets.ram.free" }) do
  local command
  sbar.exec = function(value) command = value end
  listeners["mouse.clicked"][name]()
  assert(command:find("stats_menu.applescript", 1, true) and command:match("RAM$"))
end
print("Empty-space hide/reappear, RAM accounting/rows/Stats clicks, and Wi-Fi direction/reset/error tests passed.")

local waller_status = 1
sbar.exec = function(command, callback)
  assert(command == "pgrep -x Waller >/dev/null")
  callback("", waller_status)
end
require("items.widgets.waller")
local update_waller = listeners.routine["widgets.waller"]
assert(items["widgets.waller"].properties.drawing == false)
update_waller()
assert(items["widgets.waller"].properties.drawing == false)
waller_status = 0
update_waller()
assert(items["widgets.waller"].properties.drawing == true)
assert(items["widgets.waller.padding"].properties.drawing == true)
waller_status = 1
update_waller()
assert(items["widgets.waller"].properties.drawing == false)
assert(items["widgets.waller.padding"].properties.drawing == false)
waller_status = 2
update_waller()
assert(items["widgets.waller"].properties.drawing == false)
print("Waller open/closed/error visibility tests passed.")
