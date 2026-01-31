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
}
