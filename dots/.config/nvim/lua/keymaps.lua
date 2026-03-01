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
keymap("n", "<leader>gC", "<cmd>FzfLua git_commits<cr>", { desc = "Git commits" })

-- ============================================================================
-- Explorer
-- ============================================================================

keymap("n", "<C-e>", "<cmd>Neotree toggle reveal<cr>")
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
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Goto Definition" })
keymap("n", "gr", vim.lsp.buf.references, { desc = "References", nowait = true })
keymap("n", "gI", vim.lsp.buf.implementation, { desc = "Goto Implementation" })
keymap("n", "gy", vim.lsp.buf.type_definition, { desc = "Goto T[y]pe Definition" })
keymap("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
keymap("n", "gK", vim.lsp.buf.signature_help, { desc = "Signature Help" })
keymap("n", "gx", "<cmd>lua require('gx').open()<cr>", { desc = "Open link" })

-- ============================================================================
-- Diagnostics
-- ============================================================================

keymap("n", "<leader>xx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics" })
keymap("n", "<leader>xX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics (workspace)" })
keymap("n", "<leader>xq", "<cmd>FzfLua quickfix<cr>", { desc = "Quickfix" })

-- ============================================================================
-- Session
-- ============================================================================

keymap("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore Session" })

keymap("n", "<leader>qS", function()
  require("persistence").select()
end, { desc = "Select Session" })

keymap("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore Last Session" })

keymap("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't Save Current Session" })

keymap("n", "<leader>qr", function()
  require("persistence").save()
  -- Create marker file so session is restored after restart
  local marker_file = vim.fn.stdpath("cache") .. "/restart_marker"
  vim.fn.writefile({}, marker_file)
  vim.cmd("restart")
end, { desc = "Restart and restore session" })

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
