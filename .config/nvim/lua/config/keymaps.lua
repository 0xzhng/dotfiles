-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Allow tmux to handle <C-h/j/k/l> when vim splits can't move further
for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
  pcall(vim.keymap.del, "n", key)
end

local map = vim.keymap.set
local opts = { silent = true }

map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", vim.tbl_extend("keep", { desc = "Go to left pane" }, opts))
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", vim.tbl_extend("keep", { desc = "Go to lower pane" }, opts))
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", vim.tbl_extend("keep", { desc = "Go to upper pane" }, opts))
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", vim.tbl_extend("keep", { desc = "Go to right pane" }, opts))
