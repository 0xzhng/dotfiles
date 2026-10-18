local colors = require("colors")
local settings = require("settings")

local codex = sbar.add("item", "widgets.codexbar", {
  position = "left",
  icon = { string = ":openai:", color = colors.yellow, font = { family = "sketchybar-app-font", style = "Regular", size = 17 } },
  label = { string = "--", color = colors.white },
  background = { drawing = false, border_width = 0 },
  padding_left = 3, padding_right = 3, update_freq = 120,
  click_script = 'osascript "$CONFIG_DIR/plugins/codexbar_menu.applescript"',
})
sbar.add("item", { position = "left", width = settings.group_paddings })

local busy = false
codex:subscribe({ "routine", "forced", "system_woke" }, function()
  if busy then return end
  busy = true
  -- OAuth avoids browser-cookie access prompts; do not cache account data on disk.
  sbar.exec("codexbar usage --provider codex --source oauth --format json 2>/dev/null", function(result, code)
    busy = false
    local payload = code == 0 and type(result) == "table" and result[1] or nil
    local label, remaining = require("helpers.codex_usage").format(payload)
    codex:set({ label = {
      string = label,
      color = remaining and remaining <= 10 and colors.red or colors.white,
    } })
  end)
end)
