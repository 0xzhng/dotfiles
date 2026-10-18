-- Keep pointer motion out of macOS's top-edge menu-reveal strip.
-- SketchyBar remains clickable below it; CodexBar's AX-pressed menu still works.
local types = hs.eventtap.event.types
return hs.eventtap.new({
  types.mouseMoved, types.leftMouseDragged, types.rightMouseDragged, types.otherMouseDragged,
}, function(event)
  local point = event:location()
  for _, screen in ipairs(hs.screen.allScreens()) do
    local frame = screen:fullFrame()
    if point.x >= frame.x and point.x < frame.x + frame.w
      and point.y >= frame.y and point.y < frame.y + 3 then
      local safe = { x = point.x, y = frame.y + 3 }
      -- WindowServer watches the actual cursor, not just the forwarded event.
      hs.mouse.absolutePosition(safe)
      event:location(safe)
      break
    end
  end
  return false
end):start()
