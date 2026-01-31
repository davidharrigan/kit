return {
  -- Fuzzy finder powered by fzf
  {
    "ibhagwan/fzf-lua",
    config = function()
      local actions = require("fzf-lua").actions
      local icons = require("config.icons")

      require("fzf-lua").setup({
        defaults = {
          file_icons = "mini",
        },
        winopts = {
          row = 0.5,
          height = 0.9,
        },
        files = {
          -- formatter = "path.filename_first",
          actions = {
            ["ctrl-i"] = { fn = actions.toggle_ignore, reload = true },
            ["ctrl-h"] = { fn = actions.toggle_hidden, reload = true },
          },
        },
        buffers = {
          actions = {
            -- actions inherit from 'actions.files' and merge
            -- by supplying a table of functions we're telling
            -- fzf-lua to not close the fzf window, this way we
            -- can resume the buffers picker on the same window
            -- eliminating an otherwise unaesthetic win "flash"
            ["ctrl-x"] = { fn = actions.buf_del, reload = true },
          },
        },
        diagnostics = {
          file_icons = true,
        },
        complete_path = {
          cmd = nil, -- default: auto detect fd|rg|find
          complete = { ["enter"] = actions.complete },
          word_pattern = nil, -- default: "[^%s\"']*"
        },
        lsp = {
          symbols = {
            symbol_icons = icons.kinds,
            symbol_hl = function(s)
              return "CmpItemKind" .. s
            end,
            -- prepend parent to symbol
            -- parent_postfix = ".",
            fzf_opts = {
              ["--with-nth"] = "-1", -- show only last field (symbol name)
              ["--delimiter"] = "\t", -- tab delimiter
            },
          },
        },
      })
      -- Register fzf-lua for vim.ui.select
      require("fzf-lua").register_ui_select()
    end,
  },
  -- Code outline window showing symbols (functions, classes, etc.)
  {
    "stevearc/aerial.nvim",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local icons = require("config.icons")
      require("aerial").setup({
        icons = icons.kinds,
      })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  -- File explorer that lets you edit the filesystem like a buffer
  {
    "stevearc/oil.nvim",
    config = function()
      -- Helper function to parse git command output
      local function parse_output(proc)
        local result = proc:wait()
        local ret = {}
        if result.code == 0 then
          for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
            -- Remove trailing slash
            line = line:gsub("/$", "")
            ret[line] = true
          end
        end
        return ret
      end

      -- Build git status cache
      local function new_git_status()
        return setmetatable({}, {
          __index = function(self, key)
            local ignore_proc = vim.system(
              { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
              {
                cwd = key,
                text = true,
              }
            )
            local tracked_proc = vim.system({ "git", "ls-tree", "HEAD", "--name-only" }, {
              cwd = key,
              text = true,
            })
            local ret = {
              ignored = parse_output(ignore_proc),
              tracked = parse_output(tracked_proc),
            }

            rawset(self, key, ret)
            return ret
          end,
        })
      end
      local git_status = new_git_status()

      -- Clear git status cache on refresh
      local refresh = require("oil.actions").refresh
      local orig_refresh = refresh.callback
      refresh.callback = function(...)
        git_status = new_git_status()
        orig_refresh(...)
      end

      require("oil").setup({
        skip_confirm_for_simple_edits = true,
        float = {
          preview_split = "right",
        },
        view_options = {
          is_hidden_file = function(name, bufnr)
            local dir = require("oil").get_current_dir(bufnr)
            local is_dotfile = vim.startswith(name, ".") and name ~= ".."
            -- if no local directory (e.g. for ssh connections), just hide dotfiles
            if not dir then
              return is_dotfile
            end
            -- dotfiles are considered hidden unless tracked
            if is_dotfile then
              return not git_status[dir].tracked[name]
            else
              -- Check if file is gitignored
              return git_status[dir].ignored[name]
            end
          end,
        },
        keymaps = {
          ["g?"] = { "actions.show_help", mode = "n" },
          ["<CR>"] = "actions.select",
          ["<C-s>"] = { "actions.select", opts = { vertical = true } },
          ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = { "actions.close", mode = "n" },
          ["<C-l>"] = "actions.refresh",
          ["<C-o>"] = { "actions.parent", mode = "n" },
          ["_"] = { "actions.open_cwd", mode = "n" },
          ["`"] = { "actions.cd", mode = "n" },
          ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
          ["gs"] = { "actions.change_sort", mode = "n" },
          ["gx"] = "actions.open_external",
          ["g."] = { "actions.toggle_hidden", mode = "n" },
        },
      })
    end,
  },
  -- File explorer tree sidebar
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
  },
}
