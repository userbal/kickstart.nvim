-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'tpope/vim-fugitive',

  -- Required for neo-tree icons
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Vue 3 and TypeScript development plugins
  {
    -- Auto close and rename HTML tags
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
    },
  },

  {
    -- Better commenting with support for Vue files
    'numToStr/Comment.nvim',
    event = 'VeryLazy',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
      -- Enable nvim-ts-context-commentstring integration
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end,
  },

  {
    -- Enhanced TypeScript support
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    ft = { 'typescript', 'typescriptreact', 'vue' },
    opts = {
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },

  -- Database client
  {
    'tpope/vim-dadbod',
    cmd = 'DB',
  },

  -- GitHub PR review
  {
    'daliusd/ghlite.nvim',
    config = function()
      require('ghlite').setup {
        debug = false,
        view_split = 'vsplit',
        diff_split = 'vsplit',
        comment_split = 'split',
        open_command = 'open',
      }
    end,
    keys = {
      { '<leader>gPs', ':GHLitePRSelect<cr>',        silent = true, desc = '[G]it [P]R [S]elect' },
      { '<leader>gPo', ':GHLitePRCheckout<cr>',       silent = true, desc = '[G]it [P]R check[O]ut' },
      { '<leader>gPv', ':GHLitePRView<cr>',           silent = true, desc = '[G]it [P]R [V]iew' },
      { '<leader>gPc', ':GHLitePRLoadComments<cr>',   silent = true, desc = '[G]it [P]R [C]omments → quickfix' },
      { '<leader>gPd', ':GHLitePRDiff<cr>',           silent = true, desc = '[G]it [P]R [D]iff' },
      { '<leader>gPa', ':GHLitePRAddComment<cr>',     silent = true, desc = '[G]it [P]R [A]dd comment' },
      { '<leader>gPa', ':GHLitePRAddComment<cr>',     mode = 'x',    silent = true, desc = '[G]it [P]R [A]dd comment' },
      { '<leader>gPu', ':GHLitePRUpdateComment<cr>',  silent = true, desc = '[G]it [P]R [U]pdate comment' },
      { '<leader>gPx', ':GHLitePRDeleteComment<cr>',  silent = true, desc = '[G]it [P]R delete (x)' },
      { '<leader>gPb', ':GHLitePROpenComment<cr>',    silent = true, desc = '[G]it [P]R open in [B]rowser' },
    },
  },
}
