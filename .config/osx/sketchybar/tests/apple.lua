-- Run from ~/.config/sketchybar; no system actions are executed.
package.path = "./?.lua;" .. package.path
local items, commands = {}, {}
sbar = {
  add = function(_, name, properties)
    if type(name) ~= "string" then return {} end
    local item = { name = name, properties = properties, listeners = {} }
    items[name] = item
    function item:set(values)
      for key, value in pairs(values) do
        if key == "popup" and value.drawing == "toggle" then
          self.properties.popup.drawing = not self.properties.popup.drawing
        else
          self.properties[key] = value
        end
      end
    end
    function item:subscribe(events, callback)
      if type(events) == "string" then events = { events } end
      for _, event in ipairs(events) do self.listeners[event] = callback end
    end
    return item
  end,
  exec = function(command) commands[#commands + 1] = command end,
}
dofile("items/apple.lua")
local apple = assert(items.apple)
assert(not apple.properties.click_script, "Apple must not open the native menu")
assert(apple.properties.popup.drawing == false)
apple.listeners["mouse.clicked"]()
assert(apple.properties.popup.drawing == true)
apple.listeners["mouse.clicked"]()
assert(apple.properties.popup.drawing == false)
for _, event in ipairs({ "mouse.exited", "mouse.exited.global", "front_app_switched", "system_woke" }) do
  apple.listeners["mouse.clicked"]()
  apple.listeners[event]()
  assert(apple.properties.popup.drawing == false, event)
end
local colors = require("colors")
for _, action in ipairs({ "about", "settings", "lock", "sleep", "restart", "shutdown" }) do
  local row = assert(items["apple." .. action])
  assert(row.properties.position == "popup.apple")
  row.listeners["mouse.entered"]()
  assert(row.properties.background.color == colors.bg2)
  row.listeners["mouse.exited"]()
  assert(row.properties.background.color == colors.transparent)
  apple.listeners["mouse.clicked"]()
  row.listeners["mouse.clicked"]()
  assert(apple.properties.popup.drawing == false)
  assert(commands[#commands] == 'osascript "$CONFIG_DIR/plugins/apple_menu.applescript" ' .. action)
end
assert(#commands == 6)
print("Apple popup toggle, dismissal, hover, and all six action routes passed (system actions mocked).")
