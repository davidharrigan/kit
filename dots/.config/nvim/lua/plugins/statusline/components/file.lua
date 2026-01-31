local conditions = require("heirline.conditions")

-- File component
return {
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
      provider = " ",

      hl = { fg = "green" },
    },
    {
      condition = function()
        return not vim.bo.modifiable or vim.bo.readonly
      end,
      provider = "  ",
      hl = { fg = "orange" },
    },
  },
}
