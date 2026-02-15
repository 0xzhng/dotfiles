-- e.g. in `lua/plugins/codex.lua`
return {
  "johnseth97/codex.nvim",
  lazy = true,
  cmd = { "Codex", "CodexToggle" },
  keys = {
    {
      "<leader>co",
      function()
        require("codex").open()
      end,
      desc = "Codex: Open TUI",
    },
    {
      "<leader>ct",
      function()
        require("codex").toggle()
      end,
      desc = "Codex: Toggle Codex window",
    },
  },
  opts = {
    keymaps = {
      toggle = nil, -- disable internal default mapping to avoid conflicts
      quit = "<C-q>",
    },
    border = "rounded",
    width = 0.8,
    height = 0.8,
    autoinstall = true,
  },
}
