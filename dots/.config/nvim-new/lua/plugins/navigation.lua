return {
  -- Fuzzy finder powered by fzf
  {
    "ibhagwan/fzf-lua",
    config = function()
      local actions = require("fzf-lua").actions
      require("fzf-lua").setup({
        defaults = {
          file_icons = "mini",
        },
        winopts = {
          row = 0.5,
          height = 0.9,
        },
        files = {
          previewer = true,
          -- actions = {
          --   files = {
          --     ["enter"] = actions.file_edit_or_qf,
          --     ["ctrl-s"] = actions.file_split,
          --     ["ctrl-v"] = actions.file_vsplit,
          --     ["alt-q"] = actions.file_sel_to_qf,
          --     ["alt-Q"] = actions.file_sel_to_ll,
          --     ["alt-i"] = actions.toggle_ignore,
          --     ["alt-h"] = actions.toggle_hidden,
          --     ["alt-f"] = actions.toggle_follow,
          --   },
          -- },
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
      })
    end,
  },
  -- Code outline window showing symbols (functions, classes, etc.)
  {
    "stevearc/aerial.nvim",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      require("aerial").setup({
        icons = {
          Array = " ",
          Boolean = "󰨙 ",
          Class = " ",
          Codeium = "󰘦 ",
          Color = " ",
          Control = " ",
          Collapsed = " ",
          Constant = "󰏿 ",
          Constructor = " ",
          Copilot = " ",
          Enum = " ",
          EnumMember = " ",
          Event = " ",
          Field = " ",
          File = " ",
          Folder = " ",
          Function = "󰊕 ",
          Interface = " ",
          Key = " ",
          Keyword = " ",
          Method = require("mini.icons").get("lsp", "method") .. " ",
          Module = " ",
          Namespace = "󰦮 ",
          Null = " ",
          Number = "󰎠 ",
          Object = " ",
          Operator = " ",
          Package = " ",
          Property = " ",
          Reference = " ",
          Snippet = "󱄽 ",
          String = " ",
          Struct = "󰆼 ",
          Supermaven = " ",
          TabNine = "󰏚 ",
          Text = " ",
          TypeParameter = " ",
          Unit = " ",
          Value = " ",
          Variable = "󰀫 ",
        },
      })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  -- File explorer that lets you edit the filesystem like a buffer
  {
    "stevearc/oil.nvim",
    opts = {
      skip_confirm_for_simple_edits = true,
      float = {
        preview_split = "right",
      },
      -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
      -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
      -- Additionally, if it is a string that matches "actions.<name>",
      -- it will use the mapping at require("oil.actions").<name>
      -- Set to `false` to remove a keymap
      -- See :help oil-actions for a list of all available actions
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
    },
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
