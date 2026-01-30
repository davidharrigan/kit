return {
  -- Configuration for built-in LSP client with Mason for installing servers
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", config = {} },
      { "mason-org/mason-lspconfig.nvim", config = {} },
      { "WhoIsSethDaniel/mason-tool-installer.nvim", config = {} },
    },
    opts = {
      ensure_installed = {
        "golangci_lint_ls",
        "gopls",
        "lua_ls",
        "prettier",
        "stylua",
        "tinymist",
        "typstyle",
        -- "yamlls",
      },
    },
    config = function(opts)
      require("mason").setup()
      require("mason-lspconfig").setup()
      require("mason-tool-installer").setup({ ensure_installed = opts.ensure_installed })
    end,
  },
  -- },
  -- Lightweight formatter plugin with format-on-save support
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
        typst = { "typstyle" },
      },
    },
  },
  -- Pretty list for diagnostics, references, quickfix, and location lists
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
}
