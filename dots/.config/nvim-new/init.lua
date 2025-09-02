-- Global options
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-------------
-- Keymaps --
-------------
local keymap = vim.keymap.set
local leader = function(lhs, rhs, opts)
  keymap("n", "<leader>" .. lhs, rhs, opts)
end

leader("<space>", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files", nowait = true })
leader("/", "<cmd>FzfLua grep<cr>", { desc = "Fuzzy grep files", nowait = true })
leader("rs", function()
  vim.cmd("AutoSession save")
  vim.cmd('restart lua vim.notify("Restarted")')
end, { desc = "Restart and save session", noremap = true, nowait = true })

-- find
leader("fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent" })
leader("fg", "<cmd>FzfLua helptags<cr>", { desc = "Grep tags in help files" })
-- leader("fd", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Document symbols" })
leader("fd", function()
  require("aerial").fzf_lua_picker({})
end, { desc = "Document symbols" })
leader("fw", "<cmd>FzfLua lsp_workspace_symbols<cr>", { desc = "Workspace symbols" })

-- buffers
leader("bb", "<cmd>FzfLua buffers<cr>", { desc = "Search opened buffers", nowait = true })
leader("bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
keymap("n", "L", "<cmd>bnext<cr>")
keymap("n", "H", "<cmd>bprev<cr>")
leader("bp", "<cmd>bprev<cr>", { desc = "Prev buffer" })
leader("bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

-- explore
leader("e", function()
  local oil = require("oil")
  if vim.w.is_oil_win then
    oil.close()
  else
    oil.open_float(nil, { preview = { vertical = true } })
  end
end, { desc = "Toggle explorer" })

leader("E", function()
  require("oil").toggle_float(vim.fn.getcwd())
end, { desc = "Toggle explorer (cwd)" })

-- terminal
keymap("n", "<C-/>", function()
  Snacks.terminal(nil, { cwd = vim.fn.getcwd() })
end, { desc = "Terminal" })
keymap("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- code
leader("cf", vim.lsp.buf.format, { desc = "Format" })

-- treesitter
local function args(...)
  return { ... }
end

local function map_textobj_select(mappings)
  for lhs, config in pairs(mappings) do
    local params, opts = config[1], config[2]
    keymap({ "n", "x", "o" }, lhs, function()
      require("nvim-treesitter-textobjects.select").select_textobject(params[1], params[2])
    end, opts)
  end
end

map_textobj_select({
  -- todo: i delays insert mode
  -- ["af"] = { args("@function.outer", "textobjects"), { desc = "Select outer function" } },
  -- ["if"] = { args("@function.inner", "textobjects"), { desc = "Select inner function" } },
  -- ["ac"] = { args("@class.outer", "textobjects"), { desc = "Select outer class" } },
  -- ["ic"] = { args("@class.inner", "textobjects"), { desc = "Select inner class" } },
  -- ["as"] = { args("@local.scope", "locals"), { desc = "Select local scope" } },
})

local function map_textobj_move(mappings)
  for lhs, config in pairs(mappings) do
    local func_name, params, opts = config[1], config[2], config[3]
    keymap({ "n", "x", "o" }, lhs, function()
      require("nvim-treesitter-textobjects.move")[func_name](params[1], params[2])
    end, opts)
  end
end

map_textobj_move({
  ["]f"] = { "goto_next_start", args("@function.outer", "textobjects") },
  ["]F"] = { "goto_next_end", args("@function.outer", "textobjects") },
  ["[f"] = { "goto_previous_start", args("@function.outer", "textobjects") },
  ["[F"] = { "goto_previous_end", args("@function.outer", "textobjects") },

  ["]]"] = { "goto_next_start", args("@class.outer", "textobjects") },
  ["]["] = { "goto_next_end", args("@class.outer", "textobjects") },
  ["[["] = { "goto_previous_start", args("@class.outer", "textobjects") },
  ["[]"] = { "goto_previous_end", args("@class.outer", "textobjects") },

  -- ["]o"] = { "goto_next_start", args({ "@loop.inner", "@loop.outer" }, "textobjects") },
  -- ["]s"] = { "goto_next_start", args("@local.scope", "locals") },
  -- ["]z"] = { "goto_next_start", args("@fold", "folds") },
  -- ["]d"] = { "goto_next", args("@conditional.outer", "textobjects") },
  -- ["[d"] = { "goto_previous", args("@conditional.outer", "textobjects") },
})
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

local opt = vim.opt
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 4 -- Size of an indent
opt.softtabstop = 4 -- Number of spaces tabs count for
opt.tabstop = 4 -- Number of spaces in a tab
opt.smartindent = true -- Insert indents automatically

opt.colorcolumn = "120" -- Highlight column 80
--opt.signcolumn = "yes:1" -- Always show sign column
opt.termguicolors = true -- Enable true colors
opt.ignorecase = true -- Ignore case in search
opt.swapfile = false -- Disable swap files
opt.listchars = "tab: ,multispace:|   ,eol: " -- Characters to show for tabs, spaces, and end of line
opt.list = true -- Show whitespace characters

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

--------------
-- Autocmds --
--------------
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight yanked text
local highlight_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 170 })
  end,
  group = highlight_group,
})

----------------
-- Diagnostic --
----------------
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
})

-------------
-- Plugins --
-------------
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  change_detection = { enabled = false },
})
