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
│   ├── keymaps.lua       # Keyboard mappings (organized by functional sections)
│   └── plugins/          # Plugin specifications (auto-loaded by lazy.nvim)
│       ├── completion.lua    # Completion (blink.cmp)
│       ├── git.lua           # Git plugins (gitsigns, gitlinker)
│       ├── lsp.lua           # LSP, formatting, diagnostics
│       ├── navigation.lua    # File navigation (fzf, aerial, oil, neo-tree)
│       ├── session.lua       # Session & UI utilities (snacks, auto-session, which-key)
│       ├── treesitter.lua    # Syntax parsing & text objects
│       ├── ui.lua            # UI plugins
│       └── statusline/
│           ├── init.lua          # Statusline setup
│           └── components/       # Individual statusline components (9 files)
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
- Keymaps are organized in a single `keymaps.lua` file by functional sections (Find/Search, Buffers, Git, Explorer, Terminal, Code/LSP, Diagnostics/Trouble, Session, Treesitter)
- Statusline components are modularized into individual files under `statusline/components/`
