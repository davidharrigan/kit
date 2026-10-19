-------------
-- Options --
-------------
-- https://neovim.io/doc/user/options.html

-- Buffer options
-- vim.bo.expandtab = true -- Use spaces instead of tabs
-- vim.bo.shiftwidth = 4 -- Size of an indent
-- vim.bo.softtabstop = 4 -- Number of spaces tabs count for
-- vim.bo.tabstop = 4 -- Number of spaces in a tab
-- vim.bo.smartindent = true -- Insert indents automatically
-- vim.bo.autoindent = true
--
local opt = vim.opt

opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 4 -- Size of an indent
opt.softtabstop = 4 -- Number of spaces tabs count for
opt.tabstop = 4 -- Number of spaces in a tab
opt.smartindent = true -- Insert indents automatically

opt.colorcolumn = "80" -- Highlight column 80
opt.textwidth = 80 -- Wrap text at 120 columns (used by gq)
--opt.signcolumn = "yes:1" -- Always show sign column
opt.termguicolors = true -- Enable true colors
opt.ignorecase = true -- Ignore case in search
opt.swapfile = false -- Disable swap files
-- opt.listchars = "tab:  ,multispace:|   ,eol: " -- Characters to show for tabs, spaces, and end of line
-- opt.list = true -- Show whitespace characters

-- opt.shiftround = true -- Round indent to multiple of shiftwidth
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers
opt.numberwidth = 2 -- Width of the line number column
opt.wrap = false -- Disable line wrapping
opt.cursorline = true -- Highlight the current line
opt.scrolloff = 8 -- Keep 8 lines above and below the cursor
-- opt.inccommand = "nosplit" -- Shows the effects of a command incrementally in the buffer
opt.completeopt = { "menuone", "popup", "noinsert" } -- Options for completion menu
opt.winborder = "rounded" -- Use rounded borders for windows
-- opt.hlsearch = false -- Disable highlighting of search results

opt.undofile = true
opt.undolevels = 10000

opt.laststatus = 3 -- global statusline
opt.cmdheight = 0
opt.showmode = false

opt.smoothscroll = true

-- folds
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
-- opt.foldlevelstart = 0
vim.opt.foldcolumn = "1"
opt.foldnestmax = 4
-- Fold glyphs for the fold column. These match heirline-components' fold icons
-- so that if Neovim ever falls back to the native foldcolumn (e.g. before the
-- heirline statuscolumn attaches) it shows chevrons instead of fold-level digits.
opt.fillchars = vim.tbl_extend("force", vim.opt.fillchars:get(), {
  foldopen = vim.fn.nr2char(0xf47c),
  foldclose = vim.fn.nr2char(0xf460),
  foldsep = " ",
})
