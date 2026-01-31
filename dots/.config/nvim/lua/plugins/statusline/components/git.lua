local conditions = require("heirline.conditions")

-- Git component
return {
  Branch = {
    condition = conditions.is_git_repo,
    init = function(self)
      self.status_dict = vim.b.gitsigns_status_dict
    end,
    provider = function(self)
      return "  " .. self.status_dict.head
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
