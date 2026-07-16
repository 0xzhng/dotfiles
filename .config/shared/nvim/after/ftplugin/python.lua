-- Python-specific indentation settings
-- Ensures Tab indents by 4 spaces in Python files

vim.opt_local.expandtab = true      -- use spaces instead of tabs
vim.opt_local.shiftwidth = 4        -- size of an indent
vim.opt_local.tabstop = 4           -- number of spaces a <Tab> counts for
vim.opt_local.softtabstop = 4       -- number of spaces a <Tab> inserts

-- Keep indentation predictable for Python
vim.opt_local.smartindent = false
vim.opt_local.autoindent = true

