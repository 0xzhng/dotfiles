return {
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    build = ':UpdateRemotePlugins',
    init = function()
      -- this is an example, not a default. Please see the readme for more configuration options
      vim.g.molten_output_win_max_height = 12
    end,
    keys = {
      {
        '<leader>mi',
        ':MoltenInit python3<CR>',
        desc = 'Molten: init python kernel',
      },
      {
        '<leader>mm',
        ':MoltenEvaluateOperator<CR>',
        mode = 'n',
        desc = 'Molten: run motion',
      },
      {
        '<leader>mv',
        ':<C-U>MoltenEvaluateVisual<CR>',
        mode = 'v',
        desc = 'Molten: run selection',
      },
      {
        '<leader>mo',
        ':MoltenEnterOutput<CR>',
        desc = 'Molten: enter output window',
      },
      {
        '<leader>mx',
        ':MoltenInterrupt<CR>',
        desc = 'Molten: interrupt kernel',
      },
    },
  },
}
