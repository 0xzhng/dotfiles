local M = {}

function M.memory(result)
  local total = tonumber(result:match("^(%d+)"))
  local page_size = tonumber(result:match("page size of (%d+) bytes"))
  if not total or total <= 0 or not page_size then return nil end
  local pages = {}
  for _, field in ipairs({
    "Pages active", "Pages inactive", "Pages speculative", "Pages wired down",
    "Pages occupied by compressor", "Pages purgeable", "File%-backed pages",
  }) do
    local count = tonumber(result:match("\n" .. field .. ":%s+(%d+)"))
    if not count then return nil end
    pages[#pages + 1] = count
  end
  -- Activity Monitor-style allocation excludes reclaimable file cache/purgeable pages.
  local used = (pages[1] + pages[2] + pages[3] + pages[4] + pages[5] - pages[6] - pages[7]) * page_size
  if used < 0 or used > total then return nil end
  return used, total - used
end

function M.rate(bytes)
  if bytes < 1024 then return string.format("%.0f B/s", bytes) end
  if bytes < 1024^2 then return string.format("%.1f KB/s", bytes / 1024) end
  if bytes < 1024^3 then return string.format("%.1f MB/s", bytes / 1024^2) end
  return string.format("%.1f GB/s", bytes / 1024^3)
end

return M
