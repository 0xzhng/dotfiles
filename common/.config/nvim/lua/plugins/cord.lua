return {
  {
    'vyfor/cord.nvim',
    build = ':Cord update', -- keep this as-is
    config = function()
      require('cord').setup({
        idle = {
          enabled = false,
          show_status = false,
          timeout = 99999999,
          ignore_focus = false,
          unidle_on_focus = false,
          smart_idle = false,
          details = '',
          state = '',
          tooltip = '',
          icon = '',
        },
        editor = {
          client = 'lazyvim',
        },
        timestamp = {
          enabled = true,
          reset_on_idle = false,
          reset_on_change = false,
        },
        display = {
          theme = 'default',
        },
      })
    end,
  },
}
