local M = {}

function M.format(payload)
  if type(payload) ~= "table" or type(payload.usage) ~= "table" then return "--", nil end
  local lowest
  for _, key in ipairs({ "primary", "secondary" }) do
    local window = payload.usage[key]
    local used = type(window) == "table" and tonumber(window.usedPercent) or nil
    if used and used == used and used >= 0 and used <= 100 then
      local remaining = math.floor(100 - used + 0.5)
      lowest = math.min(lowest or remaining, remaining)
    end
  end
  if not lowest then return "--", nil end
  return lowest .. "%", lowest
end

return M
