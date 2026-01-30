-- Workaround for gopls not supporting semanticTokensProvider
-- https://github.com/golang/go/issues/54531
Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
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

return {
  settings = {
    gopls = {
      -- Enable automatic completion of unimported packages
      completeUnimported = true,
      -- Use gofumpt for stricter formatting
      gofumpt = true,
      -- Enable static analysis
      staticcheck = true,
      -- Enable semantic tokens for better syntax highlighting
      semanticTokens = true,
      -- Use placeholders for function parameters in completion
      usePlaceholders = true,
      -- Code lenses
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      -- Inlay hints
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      -- Static analysis
      analyses = {
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      -- Filter out directories from completion/analysis
      directoryFilters = {
        "-.git",
        "-.vscode",
        "-.idea",
        "-.vscode-test",
        "-node_modules",
      },
    },
  },
}
