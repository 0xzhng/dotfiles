local M = {}
-- Stats' M5 CPU super/performance-core sensors, matching this Mac's M5 Pro.
local cpu_keys = {}
for _, key in ipairs({
  "Tp00", "Tp04", "Tp08", "Tp0C", "Tp0G", "Tp0K",
  "Tp0O", "Tp0R", "Tp0U", "Tp0X", "Tp0a", "Tp0d",
  "Tp0g", "Tp0j", "Tp0m", "Tp0p", "Tp0u", "Tp0y",
}) do cpu_keys[key] = true end

function M.average(output)
  local total, count = 0, 0
  for key, raw in output:gmatch("%[([%w]+)%]%s+([%d%.%-]+)") do
    local value = tonumber(raw)
    if cpu_keys[key] and value and value > 0 and value < 130 then
      total, count = total + value, count + 1
    end
  end
  if count == 0 then return nil end
  return total / count
end

return M
