return {
  settings = {
    gopls = {
      -- Enable automatic completion of unimported packages
      completeUnimported = true,
      -- Disable staticcheck (golangci-lint provides more comprehensive linting)
      staticcheck = false,
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
