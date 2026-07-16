-- Keymaps are automatically loaded on the VeryLazy event
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

map("n", "<A-h>", "<cmd>vertical resize -2<cr>", vim.tbl_extend("keep", { desc = "Decrease window width" }, opts))
map("n", "<A-l>", "<cmd>vertical resize +2<cr>", vim.tbl_extend("keep", { desc = "Increase window width" }, opts))
map("n", "<A-j>", "<cmd>resize +2<cr>", vim.tbl_extend("keep", { desc = "Increase window height" }, opts))
map("n", "<A-k>", "<cmd>resize -2<cr>", vim.tbl_extend("keep", { desc = "Decrease window height" }, opts))

-- Delete without yanking into the default register.
-- Normal mode: <leader>d works like d but uses the black-hole register, e.g. <leader>dd, <leader>dw, <leader>dap.
-- Visual mode: select text, then <leader>d to delete it without replacing your paste register.
map("n", "<leader>d", '"_d', vim.tbl_extend("keep", { desc = "Delete without yanking" }, opts))
map("x", "<leader>d", '"_d', vim.tbl_extend("keep", { desc = "Delete without yanking" }, opts))
