return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = { enabled = true },
      notification = {
        wo = { wrap = true },
      },
    },
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {},
  },
  { "linrongbin16/gitlinker.nvim", opts = {} },
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
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
    },
  },
}
