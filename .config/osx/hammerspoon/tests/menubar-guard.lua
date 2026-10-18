local callback, actual_pointer
hs = {
  mouse = { absolutePosition = function(point) actual_pointer = point end },
  eventtap = {
    event = { types = { mouseMoved = 1, leftMouseDragged = 2, rightMouseDragged = 3, otherMouseDragged = 4 } },
    new = function(types, fn)
      assert(#types == 4)
      callback = fn
      return { start = function(self) return self end }
    end,
  },
  screen = { allScreens = function()
    return {
      { fullFrame = function() return { x = 0, y = 0, w = 1800, h = 1169 } end },
      { fullFrame = function() return { x = -1200, y = -300, w = 1200, h = 900 } end },
    }
  end },
}
dofile(os.getenv("HOME") .. "/.hammerspoon/menubar-guard.lua")
local function motion(x, y)
  local event = { point = { x = x, y = y } }
  function event:location(point)
    if point then self.point = point; return self end
    return self.point
  end
  assert(callback(event) == false)
  return event.point
end
assert(motion(100, 0).y == 3)
assert(actual_pointer.x == 100 and actual_pointer.y == 3)
assert(motion(100, 2).y == 3)
actual_pointer = nil
assert(motion(100, 20).y == 20)
assert(actual_pointer == nil)
assert(motion(-100, -300).y == -297)
assert(motion(1900, 0).y == 0)
print("Top-edge guard: clamp, normal bar access, secondary screen, and outside-screen tests passed.")
