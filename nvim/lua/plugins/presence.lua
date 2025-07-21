return {
  "andweeb/presence.nvim",
  lazy = false,
  config = function()
    require("presence").setup({
      log_level = "debug",
      ipc_socket_path = "/run/user/1000/discord-ipc-0",
      neovim_image_text = "Neovim in WSL",
      show_time = true,
    })
  end,
}

