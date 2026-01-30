local keymap = vim.keymap.set
local leader = function(lhs, rhs, opts)
  keymap("n", "<leader>" .. lhs, rhs, opts)
end

leader("<space>", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files", nowait = true })
leader("/", "<cmd>FzfLua live_grep<cr>", { desc = "Fuzzy grep files", nowait = true })
leader("rs", function()
  vim.cmd("AutoSession save")
  vim.cmd('restart lua vim.notify("Restarted")')
end, { desc = "Restart and save session", noremap = true, nowait = true })

-- find
leader("fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent" })
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

-- git
leader("gs", "<cmd>FzfLua git_status<cr>", { desc = "Git status" })
leader("gc", "<cmd>FzfLua git_commits<cr>", { desc = "Git diff" })

-- explore
keymap("n", "<C-e>", "<cmd>Neotree toggle<cr>")
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
