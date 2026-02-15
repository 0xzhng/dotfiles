-- Ensure <Tab> indents when no completion/snippet is active
-- while keeping cmp navigation when the menu is visible.

return {
  "hrsh7th/nvim-cmp",
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")
    local has_luasnip, luasnip = pcall(require, "luasnip")

    local function only_whitespace_before_cursor()
      local col = vim.fn.col('.') - 1
      if col == 0 then return true end
      local line = vim.fn.getline('.')
      return line:sub(1, col):match("^%s*$") ~= nil
    end

    local function tab(fallback)
      if cmp.visible() and not only_whitespace_before_cursor() then
        cmp.select_next_item()
      elseif has_luasnip and luasnip.jumpable(1) and not only_whitespace_before_cursor() then
        luasnip.jump(1)
      else
        fallback() -- inserts indent (respects expandtab)
      end
    end

    local function stab(fallback)
      if cmp.visible() and not only_whitespace_before_cursor() then
        cmp.select_prev_item()
      elseif has_luasnip and luasnip.jumpable(-1) and not only_whitespace_before_cursor() then
        luasnip.jump(-1)
      else
        fallback()
      end
    end

    opts.mapping = opts.mapping or {}
    opts.mapping["<Tab>"] = cmp.mapping(tab, { "i", "s" })
    opts.mapping["<S-Tab>"] = cmp.mapping(stab, { "i", "s" })
  end,
}
