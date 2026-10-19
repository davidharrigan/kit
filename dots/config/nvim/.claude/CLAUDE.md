# Neovim Configuration Testing

## Testing this configuration

To test if this Neovim configuration loads correctly:

```bash
nvim --headless +"lua print('Config loaded successfully')" +quit 2>&1
```

Or for a more complete test that checks plugins:

```bash
nvim --headless +"lua vim.print(vim.inspect(require('lazy').plugins()))" +quit 2>&1
```

### Checking for errors

After launching, check for any configuration errors or warnings:

```vim
:lua Snacks.notifier.show_history()
```

Or in headless mode:

```bash
nvim --headless +"lua vim.defer_fn(function() vim.print(vim.inspect(require('snacks.notifier').get_history())) vim.cmd('quit') end, 1000)" 2>&1
```

This displays the notification history, which will show any plugin loading errors, configuration issues, or warnings that occurred during startup.

## Project Structure

This configuration is organized as follows:

```
nvim/
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
- **IMPORTANT: ALL keymaps MUST be defined in `keymaps.lua`, NOT in plugin specs.** Keymaps are organized in a single `keymaps.lua` file by functional sections (Find/Search, Buffers, Git, Explorer, Terminal, Code/LSP, Diagnostics/Trouble, Session, Treesitter). Never use the `keys` field in plugin specifications.
- Statusline components are modularized into individual files under `statusline/components/`
