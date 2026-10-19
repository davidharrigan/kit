local conditions = require("heirline.conditions")
local icons = require("config.icons")

-- Diagnostics component
return {
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
