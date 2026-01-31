-- Highly customizable statusline, winbar, and statuscolumn framework
return {
  "rebelot/heirline.nvim",
  -- event = "VeryLazy",
  dependencies = {
    "Zeioth/heirline-components.nvim",
  },
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    -- Load components from individual files (after heirline is loaded)
    local ViMode = require("plugins.statusline.components.vimode")
    local File = require("plugins.statusline.components.file")
    local Git = require("plugins.statusline.components.git")
    local Diagnostics = require("plugins.statusline.components.diagnostics")
    local Symbols = require("plugins.statusline.components.symbols")
    local Ruler = require("plugins.statusline.components.ruler")
    local MacroRecording = require("plugins.statusline.components.macro")
    local SearchCount = require("plugins.statusline.components.search")
    local statuscolumn = require("plugins.statusline.components.statuscolumn")
    local tc = require("ayu.colors")
    local utils = require("heirline.utils")
    local conditions = require("heirline.conditions")
    local colors = {
      black = "#000000",
      bright_bg = vim.g.terminal_color_8,
      bright_fg = vim.g.terminal_color_15,

      red = vim.g.terminal_color_9,
      dark_red = vim.g.terminal_color_1,
      green = vim.g.terminal_color_10,
      blue = vim.g.terminal_color_12,
      gray = "#565B66", -- utils.get_highlight("NonText").fg,
      orange = utils.get_highlight("Statement").fg,
      purple = utils.get_highlight("Constant").fg,
      cyan = vim.g.terminal_color_14,

      statusline_bg = vim.g.terminal_color_4,

      diag_warn = utils.get_highlight("DiagnosticWarn").fg,
      diag_error = utils.get_highlight("DiagnosticError").fg,
      diag_hint = utils.get_highlight("DiagnosticHint").fg,
      diag_info = utils.get_highlight("DiagnosticInfo").fg,

      git_del = utils.get_highlight("DiffRemoved").fg,
      git_add = utils.get_highlight("DiffAdded").fg,
      git_change = utils.get_highlight("Changed").fg,
    }

    local heirline = require("heirline")
    local lib = require("heirline-components.all")
    heirline.load_colors(lib.hl.get_colors())
    lib.init.subscribe_to_events()

    local Align = { provider = "%=" }
    heirline.setup({
      winbar = {
        init = function(self)
          self.bufnr = vim.api.nvim_get_current_buf()
        end,
        File.Icon,
        File.Flags,
        File.Name,
      },
      statuscolumn = {
        init = function(self)
          self.bufnr = vim.api.nvim_get_current_buf()
        end,
        lib.component.foldcolumn(),
        lib.component.signcolumn(),
        lib.component.numbercolumn(),
      } or nil,
      statusline = {
        hl = { fg = "fg", bg = "black" },
        ViMode,
        Git.Branch,
        Diagnostics,
        Symbols,

        Align,

        MacroRecording,
        Git.Changes,
        Ruler,
        SearchCount,
      },
      opts = {
        colors = colors,
        disable_winbar_cb = function(args)
          return conditions.buffer_matches({
            buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
            filetype = { "alpha", "codecompanion", "oil", "lspinfo", "snacks_dashboard", "toggleterm" },
          }, args.buf)
        end,
      },
    })
  end,
}
