return {
  {
    dir = vim.fn.expand '~/Tools/git-rewind',
    name = 'git-rewind',
    cmd = { 'GitRewind', 'GitRewindRange' },
    keys = {
      { '<leader>gr', '<cmd>GitRewind<CR>', desc = '[G]it [R]ewind file' },
      { '<leader>gr', ':GitRewindRange<CR>', mode = 'x', desc = '[G]it [R]ewind selected lines' },
    },
  },
}
