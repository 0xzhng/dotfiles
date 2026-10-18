local M = {}

function M.mode(custom, source)
  local section, power, low, high
  for line in custom:gmatch("[^\r\n]+") do
    local heading = line:match("^(.-):%s*$")
    if heading then section = heading end
    if section == source then
      power = tonumber(line:match("^%s*powermode%s+(%d+)")) or power
      low = tonumber(line:match("^%s*lowpowermode%s+(%d+)")) or low
      high = tonumber(line:match("^%s*highpowermode%s+(%d+)")) or high
    end
  end
  if power and power >= 0 and power <= 2 then return power end
  if high == 1 then return 2 end
  if low == 1 then return 1 end
  if high == 0 or low == 0 then return 0 end
  return nil
end

function M.color(mode)
  if mode == 1 then return 0xfffabd2f end -- Low Power: yellow
  if mode == 0 then return 0xffffffff end -- Automatic: white
  if mode == 2 then return 0xffb8bb26 end -- High Power: Gruvbox green
  return 0xff928374 -- Unknown/unavailable: don't imply Automatic
end

return M
