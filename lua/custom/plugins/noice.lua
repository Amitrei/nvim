return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('noice').setup {
      cmdline = {
        view = 'cmdline_popup',
      },

      notify = {
        enabled = false,
      },

      messages = {
        enabled = false,
      },

      routes = {
        {
          filter = {
            event = 'msg_show',
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = 'notify',
          },
          opts = { skip = true },
        },
      },

      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },

      presets = {
        bottom_search = true,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    }
  end,
}
