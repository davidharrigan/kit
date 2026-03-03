local ai_enabled = not vim.env.NVIM_AI_DISABLED

return {
  {
    "coder/claudecode.nvim",
    enabled = ai_enabled,
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        provider = "none",
      },
    },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    enabled = ai_enabled,
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  {
    "giuxtaposition/blink-cmp-copilot",
    enabled = ai_enabled,
    dependencies = { "zbirenbaum/copilot.lua" },
  },
}
