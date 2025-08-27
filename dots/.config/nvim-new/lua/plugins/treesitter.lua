local function select_textobject(query_string, query_group)
  return function()
    require("nvim-treesitter-textobjects.select").select_textobject(query_string, query_group)
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install({
        "bash",
        "c",
        "css",
        "csv",
        "diff",
        "gitcommit",
        "gitignore",
        "go",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
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
