local utils = require("heirline.utils")
local conditions = require("heirline.conditions")
local v, fn, api = vim.v, vim.fn, vim.api
local icons = require("config.icons")

-- ViMode components.
local ViMode = {
  init = function(self)
    self.mode = vim.fn.mode(1) -- :h mode()
    self.mode_color = { bg = self.mode_colors[self.mode:sub(1, 1)], fg = "bg" }
  end,
  static = {
    mode_names = {
      ["n"] = "NORMAL",
      ["no"] = "O-PENDING",
      ["nov"] = "O-PENDING",
      ["noV"] = "O-PENDING",
      ["no\22"] = "O-PENDING",
      ["niI"] = "NORMAL",
      ["niR"] = "NORMAL",
      ["niV"] = "NORMAL",
      ["nt"] = "NORMAL",
      ["ntT"] = "NORMAL",
      ["v"] = "VISUAL",
      ["vs"] = "VISUAL",
      ["V"] = "V-LINE",
      ["Vs"] = "V-LINE",
      ["\22"] = "V-BLOCK",
      ["\22s"] = "V-BLOCK",
      ["s"] = "SELECT",
      ["S"] = "S-LINE",
      ["\19"] = "S-BLOCK",
      ["i"] = "INSERT",
      ["ic"] = "INSERT",
      ["ix"] = "INSERT",
      ["R"] = "REPLACE",
      ["Rc"] = "REPLACE",
      ["Rx"] = "REPLACE",
      ["Rv"] = "V-REPLACE",
      ["Rvc"] = "V-REPLACE",
      ["Rvx"] = "V-REPLACE",
      ["c"] = "COMMAND",
      ["cv"] = "EX",
      ["ce"] = "EX",
      ["r"] = "REPLACE",
      ["rm"] = "MORE",
      ["r?"] = "CONFIRM",
      ["!"] = "SHELL",
      ["t"] = "TERMINAL",
      ["null"] = "",
    },
    mode_colors = {
      n = "blue",
      i = "green",
      v = "cyan",
      V = "cyan",
      ["\22"] = "cyan",
      c = "orange",
      s = "purple",
      S = "purple",
      ["\19"] = "purple",
      R = "orange",
      r = "orange",
      ["!"] = "red",
      t = "red",
    },
  },
  -- Same goes for the highlight. Now the foreground will change according to the current mode.
  hl = function(self)
    return self.mode_color
  end,
  -- Re-evaluate the component only on ModeChanged event!
  -- Also allows the statusline to be re-evaluated when entering operator-pending mode
  update = {
    "ModeChanged",
    pattern = "*:*",
    callback = vim.schedule_wrap(function()
      vim.cmd.redrawstatus()
    end),
  },
  {
    {
      provider = "",
      hl = function(self)
        return { bg = self.mode_color.fg, fg = self.mode_color.bg }
      end,
    },
    {
      provider = function(self)
        return " %2(" .. self.mode_names[self.mode] .. "%) "
      end,
    },
    {
      provider = "",
      hl = function(self)
        return { bg = self.mode_color.fg, fg = self.mode_color.bg }
      end,
    },
  },
}

-- File components.
local File = {
  Name = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(0)
    end,
    provider = function(self)
      local filename = vim.fn.fnamemodify(self.filename, ":.")
      if filename == "" then
        return "[No Name]"
      end
      if not conditions.width_percent_below(#filename, 0.75) then
        filename = vim.fn.pathshorten(filename)
      end
      return filename
    end,
  },

  Icon = {
    init = function(self)
      local icon, icon_hl = require("mini.icons").get("filetype", vim.bo.filetype)
      self.icon = icon
      self.icon_hl = icon_hl
    end,
    condition = function()
      return package.loaded["mini.icons"] ~= nil
    end,
    provider = function(self)
      return self.icon and (" " .. self.icon .. " ")
    end,
    hl = function(self)
      if self.icon_hl and vim.fn.hlexists(self.icon_hl) == 1 then
        return vim.api.nvim_get_hl(0, { name = self.icon_hl, link = false })
      end
    end,
  },

  Flags = {
    {
      condition = function()
        return vim.bo.modified
      end,
      provider = " ",

      hl = { fg = "green" },
    },
    {
      condition = function()
        return not vim.bo.modifiable or vim.bo.readonly
      end,
      provider = "  ",
      hl = { fg = "orange" },
    },
  },
}

-- Git components.
local Git = {
  Branch = {
    condition = conditions.is_git_repo,
    init = function(self)
      self.status_dict = vim.b.gitsigns_status_dict
    end,
    provider = function(self)
      return "  " .. self.status_dict.head
    end,
    hl = {
      fg = "statusline_bg",
    },
  },
  Changes = {
    condition = conditions.is_git_repo,
    init = function(self)
      self.status_dict = vim.b.gitsigns_status_dict
      self.added = self.status_dict.added or 0
      self.changed = self.status_dict.changed or 0
      self.removed = self.status_dict.removed or 0
    end,
    provider = " ",
    {
      condition = function(self)
        return self.added > 0
      end,
      provider = function(self)
        -- local count = self.status_dict.added or 0
        -- return count > 0 and ("+" .. count)
        return "+" .. self.added
      end,
      hl = { fg = "git_add" },
    },
    {
      condition = function(self)
        return self.added > 0 and (self.changed > 0 or self.removed > 0)
      end,
      provider = " ",
    },
    {
      condition = function(self)
        return self.changed > 0
      end,
      provider = function(self)
        return "~" .. self.changed
      end,
      hl = { fg = "git_change" },
    },
    {
      condition = function(self)
        return self.added > 0 and self.changed > 0 and self.removed > 0
      end,
      provider = " ",
    },
    {
      condition = function(self)
        return self.removed > 0
      end,
      provider = function(self)
        return "-" .. self.removed
      end,
      hl = { fg = "git_del" },
    },
  },
}

-- Diagnostics component.
local Diagnostics = {
  condition = conditions.has_diagnostics,
  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    condition = function(self)
      return self.errors > 0 or self.warnings > 0
    end,
    { provider = " " },
    {
      provider = function(self)
        -- 0 is just another output, we can decide to print it or not!
        return self.errors > 0 and (icons.diagnostics.Error .. self.errors)
      end,
      hl = { fg = "diag_error" },
    },
    {
      condition = function(self)
        return self.errors > 0 and self.warnings > 0
      end,
      provider = " ",
    },
    {
      provider = function(self)
        return self.warnings > 0 and (icons.diagnostics.Warn .. self.warnings)
      end,
      hl = { fg = "diag_warn" },
    },
  },
}

-- Symbols component.
local SymbolsSeprator = {
  provider = " ▸ ",
  hl = { fg = "cyan" },
}
local Symbols = {
  condition = function()
    return package.loaded.aerial
  end,
  init = function(self)
    self.symbols = require("aerial").get_location(true) or {}
  end,
  update = "CursorMoved",
  {
    condition = function(self)
      if vim.tbl_isempty(self.symbols) then
        return false
      end
      return true
    end,
    { provider = " 󰇙 ", hl = { fg = "cyan" } },
    {
      flexible = 3,
      {
        provider = function(self)
          local symbols = {}

          for i, d in ipairs(self.symbols) do
            local symbol = {
              -- Name
              { provider = string.gsub(d.name, "%%", "%%%%"):gsub("%s*->%s*", "") },
            }

            -- Icon
            local hlgroup = string.format("Aerial%sIcon", d.kind)
            table.insert(symbol, 1, {
              provider = string.format("%s", d.icon),
              hl = (vim.fn.hlexists(hlgroup) == 1) and hlgroup or nil,
            })

            if #self.symbols >= 1 and i < #self.symbols then
              table.insert(symbol, SymbolsSeprator)
            end

            table.insert(symbols, symbol)
          end

          self[1] = self:new(symbols, 1)
        end,
      },
    },
  },
}

local Ruler = {
  condition = function(self)
    return not conditions.buffer_matches({
      filetype = self.filetypes,
    })
  end,
  -- %l = current line number
  -- %L = number of lines in the buffer
  -- %c = column number
  -- %P = percentage through file of displayed window
  provider = " %1(%l/%L%):%c %P",
  hl = { fg = "bright_bg" },
}

local MacroRecording = {
  condition = function()
    return vim.fn.reg_recording() ~= ""
  end,
  update = {
    "RecordingEnter",
    "RecordingLeave",
  },
  hl = { bg = "purple" },
  {
    {
      provider = function()
        return " 󰑊 "
      end,
      hl = { fg = "red", bold = true },
    },
    {
      provider = function()
        return vim.fn.reg_recording() .. " "
      end,
      hl = { fg = "bg", bold = true },
    },
  },
}

local SearchCount = {
  condition = function()
    return vim.v.hlsearch ~= 0 -- and vim.o.cmdheight == 0
  end,
  init = function(self)
    local ok, search = pcall(vim.fn.searchcount)
    if ok and search.total then
      self.search = search
    end
  end,
  {
    {
      provider = " ",
      condition = function(self)
        return self.search and self.search.total > 0
      end,
    },
    {
      condition = function(self)
        return self.search and self.search.total > 0
      end,
      hl = function()
        return { bg = "green", fg = "gray" }
      end,
      provider = function(self)
        local search = self.search
        return string.format("[%d/%d]", search.current, math.min(search.total, search.maxcount))
      end,
    },
  },
}

---Statuscolumn configuration for heirline.nvim
---@return table
local function statuscolumn()
  local align = { provider = "%=" }
  local spacer = { provider = " ", hl = "HeirlineStatusColumn" }

  local git_ns = api.nvim_create_namespace("gitsigns_signs_")
  local function get_signs(bufnr, lnum)
    local signs = {}

    local extmarks = api.nvim_buf_get_extmarks(
      0,
      -1,
      { lnum - 1, 0 },
      { lnum - 1, -1 },
      { details = true, type = "sign" }
    )

    for _, extmark in pairs(extmarks) do
      -- Exclude gitsigns
      if extmark[4].ns_id ~= git_ns then
        signs[#signs + 1] = {
          name = extmark[4].sign_hl_group or "",
          text = extmark[4].sign_text,
          sign_hl_group = extmark[4].sign_hl_group,
          priority = extmark[4].priority,
        }
      end
    end

    table.sort(signs, function(a, b)
      return (a.priority or 0) > (b.priority or 0)
    end)

    return signs
  end

  return {
    {
      condition = function()
        return not conditions.buffer_matches({
          buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
          filetype = { "alpha", "codecompanion", "harpoon", "oil", "lspinfo", "snacks_dashboard", "toggleterm" },
        })
      end,
      static = {
        bufnr = api.nvim_win_get_buf(0),
        click_args = function(self, minwid, clicks, button, mods)
          local args = {
            minwid = minwid,
            clicks = clicks,
            button = button,
            mods = mods,
            mousepos = fn.getmousepos(),
          }
          local sign = fn.screenstring(args.mousepos.screenrow, args.mousepos.screencol)
          if sign == " " then
            sign = fn.screenstring(args.mousepos.screenrow, args.mousepos.screencol - 1)
          end
          args.sign = self.signs[sign]
          api.nvim_set_current_win(args.mousepos.winid)
          api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })

          return args
        end,
        resolve = function(self, name)
          for pattern, callback in pairs(self.handlers.Signs) do
            if name:match(pattern) then
              return vim.defer_fn(callback, 100)
            end
          end
        end,
        handlers = {
          Signs = {
            ["Neotest.*"] = function(self, args)
              require("neotest").run.run()
            end,
            ["Diagnostic.*"] = function(self, args)
              vim.diagnostic.open_float()
            end,
            ["LspLightBulb"] = function(self, args)
              vim.lsp.buf.code_action()
            end,
          },
          Fold = function(args)
            local line = args.mousepos.line
            if fn.foldlevel(line) <= fn.foldlevel(line - 1) then
              return
            end
            vim.cmd.execute("'" .. line .. "fold" .. (fn.foldclosed(line) == -1 and "close" or "open") .. "'")
          end,
          GitSigns = function(self, args)
            vim.defer_fn(function()
              require("snacks").git.blame_line()
            end, 100)
          end,
        },
      },
      init = function(self)
        self.signs = {}
      end,
      -- Signs (except for GitSigns)
      {
        init = function(self)
          local signs = get_signs(self.bufnr, v.lnum)
          self.sign = signs[1]
        end,
        provider = function(self)
          return self.sign and self.sign.text or "  "
        end,
        hl = function(self)
          return self.sign and self.sign.sign_hl_group
        end,
        on_click = {
          name = "sc_sign_click",
          update = true,
          callback = function(self, ...)
            local line = self.click_args(self, ...).mousepos.line
            local sign = get_signs(self.bufnr, line)[1]
            if sign then
              self:resolve(sign.name)
            end
          end,
        },
      },
      align,
      -- Line Numbers
      {
        provider = "%=%4{v:virtnum ? '' : &nu ? (&rnu && v:relnum ? v:relnum : v:lnum) . ' ' : ''}",
        -- on_click = {
        --   name = "sc_linenumber_click",
        --   callback = function(self, ...)
        --     self.handlers.Dap(self.click_args(self, ...))
        --   end,
        -- },
      },
      -- Folds
      {
        init = function(self)
          self.can_fold = fn.foldlevel(v.lnum) > fn.foldlevel(v.lnum - 1)
        end,
        {
          condition = function(self)
            return v.virtnum == 0 and self.can_fold
          end,
          provider = "%C",
        },
        {
          condition = function(self)
            return not self.can_fold
          end,
          spacer,
        },
        on_click = {
          name = "sc_fold_click",
          callback = function(self, ...)
            self.handlers.Fold(self.click_args(self, ...))
          end,
        },
      },
      -- Git Signs
      {
        {
          condition = function()
            return conditions.is_git_repo()
          end,
          init = function(self)
            local extmark = api.nvim_buf_get_extmarks(
              0,
              git_ns,
              { v.lnum - 1, 0 },
              { v.lnum - 1, -1 },
              { limit = 1, details = true }
            )[1]

            self.sign = extmark and extmark[4]["sign_hl_group"]
          end,
          {
            provider = "│",
            hl = function(self)
              return self.sign or { fg = "bg" }
            end,
            on_click = {
              name = "sc_gitsigns_click",
              callback = function(self, ...)
                self.handlers.GitSigns(self.click_args(self, ...))
              end,
            },
          },
        },
        {
          condition = function()
            return not conditions.is_git_repo()
          end,
          spacer,
        },
      },
    },
  }
end

return {
  statuscolumn = statuscolumn(),
  File = File,
  Git = Git,
  ViMode = ViMode,
  Diagnostics = Diagnostics,
  Symbols = Symbols,
  Ruler = Ruler,
  MacroRecording = MacroRecording,
  SearchCount = SearchCount,
}
