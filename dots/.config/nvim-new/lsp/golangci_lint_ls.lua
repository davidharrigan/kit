return {
  -- Only enable diagnostics from golangci-lint-langserver
  -- Let gopls handle everything else (completion, hover, definitions, etc.)
  init_options = {
    command = {
      "golangci-lint",
      "run",
      "--out-format",
      "json",
      "--issues-exit-code=1",
    },
  },
  -- Disable all capabilities except diagnostics to avoid conflicts with gopls
  on_attach = function(client, bufnr)
    -- Only keep diagnostic publishing
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    client.server_capabilities.completionProvider = nil
    client.server_capabilities.hoverProvider = false
    client.server_capabilities.definitionProvider = false
    client.server_capabilities.referencesProvider = false
    client.server_capabilities.renameProvider = false
    client.server_capabilities.codeActionProvider = false
  end,
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
}
