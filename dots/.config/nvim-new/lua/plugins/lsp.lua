return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_enable = true,
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        json = { "prettier" },
        lua = { "stylua" },
      },
    },
  },
}
