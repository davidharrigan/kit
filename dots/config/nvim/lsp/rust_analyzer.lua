return {
  settings = {
    ["rust-analyzer"] = {
      -- Enable automatic imports
      imports = {
        granularity = {
          group = "module",
        },
        prefix = "self",
      },
      -- Enable cargo check on save
      checkOnSave = true,
      check = {
        command = "clippy",
      },
      -- Enable procedural macro support
      procMacro = {
        enable = true,
      },
      -- Inlay hints
      inlayHints = {
        bindingModeHints = {
          enable = false,
        },
        chainingHints = {
          enable = true,
        },
        closingBraceHints = {
          enable = true,
          minLines = 25,
        },
        closureReturnTypeHints = {
          enable = "never",
        },
        lifetimeElisionHints = {
          enable = "never",
          useParameterNames = false,
        },
        maxLength = 25,
        parameterHints = {
          enable = true,
        },
        reborrowHints = {
          enable = "never",
        },
        renderColons = true,
        typeHints = {
          enable = true,
          hideClosureInitialization = false,
          hideNamedConstructor = false,
        },
      },
      -- Cargo features
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        buildScripts = {
          enable = true,
        },
      },
      -- Diagnostics
      diagnostics = {
        enable = true,
        experimental = {
          enable = true,
        },
      },
    },
  },
}
