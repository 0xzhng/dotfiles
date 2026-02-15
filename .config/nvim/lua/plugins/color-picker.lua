return {
  "ziontee113/color-picker.nvim",
  lazy = false,  -- load immediately so commands are available
  config = function()
    local opts = { noremap = true, silent = true }

    require("color-picker").setup({
      -- Example settings (optional)
      -- ["icons"] = { "ﱢ", "" },
      -- ["border"] = "rounded",
    })

    -- Normal mode picker
    vim.keymap.set("n", "<leader>cp", "<cmd>PickColor<CR>", opts)

    -- Insert mode picker
    vim.keymap.set("i", "<C-c>", "<cmd>PickColorInsert<CR>", opts)
  end,
}

