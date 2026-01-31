return {
  -- Ayu colorscheme (local development version)
  {
    -- "davidharrigan/neovim-ayu",
    dir = "~/src/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme ayu]])
    end,
  },
  -- Icon provider for various plugins
  {
    "echasnovski/mini.icons",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  -- Enhanced gx to open URLs, files, and more
  {
    "chrishrb/gx.nvim",
    event = "VeryLazy",
    opts = {
      open_browser_app = "open", -- macOS default browser
      handlers = {
        plugin = true,
        github = true,
        brewfile = true,
        package_json = true,
      },
    },
  },
}
