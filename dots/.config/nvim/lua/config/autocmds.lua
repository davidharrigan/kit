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

-- Auto-restore session after explicit restart
local session_group = augroup("SessionRestore", { clear = true })
autocmd("VimEnter", {
  callback = function()
    local marker_file = vim.fn.stdpath("cache") .. "/restart_marker"
    if vim.fn.filereadable(marker_file) == 1 then
      vim.fn.delete(marker_file)
      -- Defer to ensure persistence is loaded
      vim.defer_fn(function()
        require("persistence").load({ last = true })
        vim.notify("Session restored after restart")
      end, 100)
    end
  end,
  group = session_group,
  nested = true,
})
