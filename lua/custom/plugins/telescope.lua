return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local telescope = require 'telescope'
    local builtin = require 'telescope.builtin'
    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    -- Setup
    telescope.setup {
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Extensions
    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')

    -- 🔥 Git commit + push picker
    local function git_add_commit_push()
      local history = vim.fn.systemlist 'git log --pretty=%s -n 20 2>/dev/null'
      local bypass_sort = false

      local sorter = require('telescope.sorters').get_generic_fuzzy_sorter()
      local orig_scoring = sorter.scoring_function
      sorter.scoring_function = function(self, prompt, line, entry)
        if bypass_sort then return 0 end
        return orig_scoring(self, prompt, line, entry)
      end

      pickers
        .new({}, {
          prompt_title = 'Commit message',
          finder = finders.new_table {
            results = history,
          },
          sorter = sorter,
          attach_mappings = function(prompt_bufnr, _)
            local function sync_prompt_from_selection()
              local selection = action_state.get_selected_entry()
              if selection then
                bypass_sort = true
                action_state.get_current_picker(prompt_bufnr):set_prompt(selection[1])
                bypass_sort = false
              end
            end

            actions.move_selection_next:enhance { post = sync_prompt_from_selection }
            actions.move_selection_previous:enhance { post = sync_prompt_from_selection }

            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              local line = action_state.get_current_line()
              actions.close(prompt_bufnr)

              local msg = (line ~= '' and line) or (selection and selection[1])
              if not msg or msg == '' then
                vim.notify('Commit cancelled', vim.log.levels.INFO)
                return
              end

              vim.notify('Running git add, commit, and push...', vim.log.levels.INFO)

              vim.system({ 'git', 'add', '.' }, { text = true }, function(add_obj)
                if add_obj.code ~= 0 then
                  vim.schedule(function()
                    vim.notify(add_obj.stderr ~= '' and add_obj.stderr or 'git add failed', vim.log.levels.ERROR)
                  end)
                  return
                end

                vim.system({ 'git', 'commit', '-m', msg }, { text = true }, function(commit_obj)
                  if commit_obj.code ~= 0 then
                    vim.schedule(function()
                      vim.notify(commit_obj.stderr ~= '' and commit_obj.stderr or commit_obj.stdout or 'git commit failed', vim.log.levels.ERROR)
                    end)
                    return
                  end

                  vim.system({ 'git', 'push' }, { text = true }, function(push_obj)
                    vim.schedule(function()
                      if push_obj.code ~= 0 then
                        vim.notify(push_obj.stderr ~= '' and push_obj.stderr or 'git push failed', vim.log.levels.ERROR)
                      else
                        local out = table
                          .concat({
                            commit_obj.stdout or '',
                            push_obj.stdout or '',
                          }, '\n')
                          :gsub('^%s+', '')
                          :gsub('%s+$', '')

                        vim.notify(out ~= '' and out or 'Git commit and push completed', vim.log.levels.INFO)
                      end
                    end)
                  end)
                end)
              end)
            end)

            return true
          end,
        })
        :find()
    end

    -- Keymaps
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>gc', builtin.git_branches, { desc = '[G]it [Checkout]' })
    vim.keymap.set('n', '<leader>gp', git_add_commit_push, { desc = '[G]it commit & [P]ush' })
    vim.keymap.set('n', '<leader>fr', builtin.lsp_references, { desc = '[F]ind [R]eferences' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })

    vim.keymap.set('n', '<leader>ff', function()
      builtin.find_files {
        no_ignore = true,
        no_ignore_parent = true,
      }
    end, { desc = '[S]earch [F]iles (including ignored)' })

    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[S]earch current [W]ord' })

    vim.keymap.set('n', '<leader>/', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    vim.keymap.set('n', '<leader>fm', function()
      builtin.lsp_document_symbols { query = 'Function' }
    end, { desc = '[F]ind [M]ethod' })

    -- Override "/" for current buffer fuzzy search (this overrides the earlier one intentionally)
    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = true,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
