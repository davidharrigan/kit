local keymap = vim.keymap.set

-- ============================================================================
-- Find / Search
-- ============================================================================

keymap("n", "<leader><space>", "<cmd>FzfLua global<cr>", { desc = "Find", nowait = true })
keymap("n", "<leader>/", "<cmd>FzfLua live_grep<cr>", { desc = "Fuzzy grep files", nowait = true })
keymap("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Files", nowait = true })
keymap("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent" })

-- ============================================================================
-- Buffers
-- ============================================================================

keymap("n", "<leader>bb", "<cmd>FzfLua buffers<cr>", { desc = "Search opened buffers", nowait = true })
keymap("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
keymap("n", "<leader>bp", "<cmd>bprev<cr>", { desc = "Prev buffer" })
keymap("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

-- Quick buffer navigation
keymap("n", "H", "<cmd>bprev<cr>")
keymap("n", "L", "<cmd>bnext<cr>")

-- ============================================================================
-- Git
-- ============================================================================

keymap("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "Git status" })
keymap("n", "<leader>gc", "<cmd>FzfLua git_bcommits<cr>", { desc = "Git commits (branch)" })
keymap("n", "<leader>gC", "<cmd>FzfLua git_bcommit<cr>", { desc = "Git commits" })

-- ============================================================================
-- Explorer
-- ============================================================================

keymap("n", "<C-e>", "<cmd>Neotree toggle<cr>")
keymap("n", "<leader>e", function()
  local oil = require("oil")
  if vim.w.is_oil_win then
    oil.close()
  else
    oil.open_float(nil, { preview = { vertical = true } })
  end
end, { desc = "Toggle explorer" })

keymap("n", "<leader>E", function()
  require("oil").toggle_float(vim.fn.getcwd())
end, { desc = "Toggle explorer (cwd)" })

-- ============================================================================
-- Terminal
-- ============================================================================

keymap("n", "<C-/>", function()
  Snacks.terminal(nil, { cwd = vim.fn.getcwd() })
end, { desc = "Terminal" })
keymap("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- ============================================================================
-- Code / LSP
-- ============================================================================

keymap("n", "<leader>cc", "<cmd>FzfLua lsp_code_actions<cr>", { desc = "Code actions" })
keymap("n", "<leader>cf", vim.lsp.buf.format, { desc = "Format" })
keymap("n", "<leader>cs", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Document Symbols" })
keymap("n", "<leader>cS", "<cmd>FzfLua lsp_workspace_symbols<cr>", { desc = "Workspace symbols" })
keymap("n", "<leader>fd", function()
  require("aerial").fzf_lua_picker({})
end, { desc = "Document symbols" })
-- keymap("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
-- keymap(
--   "n",
--   "<leader>cl",
--   "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
--   { desc = "LSP Definitions / references / ... (Trouble)" }
-- )

-- ============================================================================
-- Diagnostics
-- ============================================================================

keymap("n", "<leader>xx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics" })
keymap("n", "<leader>xX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics (workspace)" })
keymap("n", "<leader>xq", "<cmd>FzfLua quickfix<cr>", { desc = "Quickfix" })

-- ============================================================================
-- Session
-- ============================================================================

keymap("n", "<leader>rs", function()
  vim.cmd("AutoSession save")
  vim.cmd('restart lua vim.notify("Restarted")')
end, { desc = "Restart and save session", noremap = true, nowait = true })

-- ============================================================================
-- Treesitter Text Objects
-- ============================================================================

local function map_textobj_move(mappings)
  for lhs, config in pairs(mappings) do
    local func_name, params, opts = config[1], config[2], config[3]
    keymap({ "n", "x", "o" }, lhs, function()
      require("nvim-treesitter-textobjects.move")[func_name](params[1], params[2])
    end, opts)
  end
end

map_textobj_move({
  ["]f"] = { "goto_next_start", { "@function.outer", "textobjects" } },
  ["]F"] = { "goto_next_end", { "@function.outer", "textobjects" } },
  ["[f"] = { "goto_previous_start", { "@function.outer", "textobjects" } },
  ["[F"] = { "goto_previous_end", { "@function.outer", "textobjects" } },

  ["]]"] = { "goto_next_start", { "@class.outer", "textobjects" } },
  ["]["] = { "goto_next_end", { "@class.outer", "textobjects" } },
  ["[["] = { "goto_previous_start", { "@class.outer", "textobjects" } },
  ["[]"] = { "goto_previous_end", { "@class.outer", "textobjects" } },
})
