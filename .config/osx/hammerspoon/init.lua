-- Prevent accidental top-edge hits that reveal the Apple menu bar.
-- Hold Ctrl+Option to bypass when you intentionally want the menu bar.

local guardHeight = 3
local pushDown = 6

local function shouldBypass()
  local mods = hs.eventtap.checkKeyboardModifiers()
  return mods.ctrl and mods.alt
end

local function keepMouseOffTopEdge()
  if shouldBypass() then
    return
  end

  local pos = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen()
  if not screen then
    return
  end

  local frame = screen:fullFrame()
  local topEdge = frame.y

  if pos.y <= (topEdge + guardHeight) then
    hs.mouse.absolutePosition({ x = pos.x, y = topEdge + pushDown })
  end
end

-- Keep references so Lua GC does not stop them.
TOP_EDGE_GUARD_TIMER = hs.timer.doEvery(0.008, keepMouseOffTopEdge)

-- Event tap catches normal pointer movement immediately.
TOP_EDGE_GUARD_TAP = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, keepMouseOffTopEdge)
TOP_EDGE_GUARD_TAP:start()
