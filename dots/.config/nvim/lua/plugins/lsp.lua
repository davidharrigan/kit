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
        "gofumpt",
        "goimports",
        "golangci_lint_ls",
        "gopls",
        "lua_ls",
        "prettier",
        "rust_analyzer",
        "stylua",
        "tinymist",
        "typstyle",
        "gofumpt",
        "goimports",
        -- "yamlls",
      },
    },
    config = function(opts)
      require("mason").setup()
      require("mason-lspconfig").setup()
      require("mason-tool-installer").setup({ ensure_installed = opts.ensure_installed })

      -- Workaround for gopls not supporting semanticTokensProvider
      -- https://github.com/golang/go/issues/54531
      Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
        -- Disable gopls formatting - let conform.nvim handle it with gofumpt/goimports
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        if not client.server_capabilities.semanticTokensProvider then
          local semantic = client.config.capabilities.textDocument.semanticTokens
          if semantic then
            client.server_capabilities.semanticTokensProvider = {
              full = true,
              legend = {
                tokenTypes = semantic.tokenTypes,
                tokenModifiers = semantic.tokenModifiers,
              },
              range = true,
            }
          end
        end
      end)
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
        go = { "goimports", "gofumpt" },
        json = { "prettier" },
        lua = { "stylua" },
        typst = { "typstyle" },
      },
    },
  },
  -- Pretty list for diagnostics, references, quickfix, and location lists
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
  },
}
