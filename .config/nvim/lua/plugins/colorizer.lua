return {
  "NvChad/nvim-colorizer.lua",
  opts = {
    user_default_options = {
      names = true,      -- "red", "green"
      rgb_fn = true,     -- rgb(), rgba()
      hsl_fn = true,     -- hsl(), hsla()
    },
  },
  config = function(_, opts)
    require("colorizer").setup(opts)
  end,
}
