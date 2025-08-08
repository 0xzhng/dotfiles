return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "black",
        "ruff",
        "clangd",
        "lua-language-server",
        "rust-analyzer",
        "css-lsp",
        "ts-standard",
        "marksman",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- Add LSP servers here safely
      local servers = {
        pyright = {},
        clangd = {},
        cssls = {},
        lua_ls = {},
        rust_analyzer = {},
        tsserver = {},
        yamlls = {},
      }

      for name, config in pairs(servers) do
        opts.servers[name] = config
      end
    end,
  },
}
