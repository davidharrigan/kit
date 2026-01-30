# Neovim Configuration Testing

## Testing this configuration

When testing if this Neovim configuration loads correctly, use the following command to ensure you're testing THIS config and not the default one:

```bash
NVIM_APPNAME=nvim-new nvim --headless +"lua print('Config loaded successfully')" +quit 2>&1
```

Or for a more complete test that checks plugins:

```bash
NVIM_APPNAME=nvim-new nvim --headless +"lua vim.print(vim.inspect(require('lazy').plugins()))" +quit 2>&1
```

## Running this config interactively

To use this config:

```bash
NVIM_APPNAME=nvim-new nvim
```

## Project Structure

This configuration is organized as follows:

```
nvim-new/
├── init.lua              # Minimal bootstrap and module loading
├── lua/
│   ├── config/           # Core configuration modules
│   │   ├── autocmds.lua      # Autocommands
│   │   ├── diagnostics.lua   # Diagnostic settings
│   │   ├── icons.lua         # Icon definitions
│   │   └── options.lua       # Vim options
│   ├── keymaps.lua       # Keyboard mappings
│   └── plugins/          # Plugin specifications (auto-loaded by lazy.nvim)
│       ├── *.lua             # Individual plugin configs
│       └── statusline/
│           ├── statusline.lua
│           └── components.lua
├── lsp/                  # LSP server configs (auto-loaded by nvim 0.11+)
│   ├── nil_ls.lua
│   └── yamlls.lua
└── .claude/
    └── CLAUDE.md         # This file
```

## Important Notes

- Neovim 0.11+ automatically loads LSP configs from the `lsp/` directory
- This config uses lazy.nvim for plugin management
- Plugin specs are auto-imported from `lua/plugins/`
