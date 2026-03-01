return {
  -- Syntax highlighting and code parsing via treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.install({
        "bash",
        "c",
        "css",
        "csv",
        "diff",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "rust",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "zig",
      })
    end,
  },
  -- Text objects based on treesitter syntax tree (e.g., select function, class)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
          },
        },
        move = {
          set_jumps = false,
        },
      })
    end,
    --  config = function()
    --      textobjects = {
    --        move = {
    --          goto_next_start = {
    --            ["]f"] = "@function.outer",
    --            ["]["] = "@class.outer",
    --            ["]a"] = "@parameter.inner",
    --          },
    --          goto_next_end = {
    --            ["]F"] = "@function.outer",
    --            ["]]"] = "@class.outer",
    --            ["]A"] = "@parameter.inner",
    --          },
    --          goto_previous_start = {
    --            ["[f"] = "@function.outer",
    --            ["[["] = "@class.outer",
    --            ["[a"] = "@parameter.inner",
    --          },
    --          goto_previous_end = {
    --            ["[F"] = "@function.outer",
    --            ["[]"] = "@class.outer",
    --            ["[A"] = "@parameter.inner",
    --          },
    --        },
    --      },
    --    })
    --  end,
  },
}
