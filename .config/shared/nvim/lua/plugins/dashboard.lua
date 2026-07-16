return {
  {
    "LazyVim/LazyVim",
    opts = {
      defaults = {
        dashboard = "dashboard-nvim",
      },
    },
  },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      local logo = [[
      ___           ___           ___           ___           ___           ___           ___
     /\  \         /\__\         /\__\         /\  \         /\  \         /\  \         /\__\
     \:\  \       /:/  /        /::|  |       /::\  \       /::\  \       /::\  \       /:/  /
      \:\  \     /:/__/        /:|:|  |      /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  /
       \:\  \   /::\  \ ___   /:/|:|  |__   /:/  \:\  \   /:/  \:\__\   /::\~\:\  \   /:/__/  ___
 _______\:\__\ /:/\:\  /\__\ /:/ |:| /\__\ /:/__/_\:\__\ /:/__/ \:|__| /:/\:\ \:\__\  |:|  | /\__\
 \::::::::/__/ \/__\:\/:/  / \/__|:|/:/  / \:\  /\ \/__/ \:\  \ /:/  / \:\~\:\ \/__/  |:|  |/:/  /
  \:\~~\~~          \::/  /      |:/:/  /   \:\ \:\__\    \:\  /:/  /   \:\ \:\__\    |:|__/:/  /
   \:\  \           /:/  /       |::/  /     \:\/:/  /     \:\/:/  /     \:\ \/__/     \::::/__/
    \:\__\         /:/  /        /:/  /       \::/  /       \::/__/       \:\__\        ~~~~
     \/__/         \/__/         \/__/         \/__/         ~~            \/__/
      ]]

      local header = vim.split(logo:gsub("^\n", ""):gsub("\n%s*$", ""), "\n")
      local width = 0
      for _, line in ipairs(header) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
      end
      for index, line in ipairs(header) do
        header[index] = line .. string.rep(" ", width - vim.fn.strdisplaywidth(line))
      end
      vim.list_extend(header, { "", "", "" })

      local opts = {
        theme = "doom",
        config = {
          header = header,
          center = {
            { icon = "  ", desc = "Find File", key = "f", action = ":lua Snacks.picker.files()" },
            { icon = "  ", desc = "Recent Files", key = "r", action = ":lua Snacks.picker.recent()" },
            { icon = "  ", desc = "Find Text", key = "g", action = ":lua Snacks.picker.grep()" },
            { icon = "󰒲  ", desc = "Lazy", key = "l", action = ":Lazy" },
            { icon = "  ", desc = "Quit", key = "q", action = ":qa" },
          },
          footer = {},
          vertical_center = true,
        },
        hide = {
          statusline = true,
          tabline = true,
          winbar = true,
        },
      }
      return opts
    end,
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#fabd2f" })
      require("dashboard").setup(opts)
    end,
  },
}
