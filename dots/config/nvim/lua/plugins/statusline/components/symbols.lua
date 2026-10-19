-- Symbols component
local SymbolsSeparator = {
  provider = " ▸ ",
  hl = { fg = "cyan" },
}

return {
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
              table.insert(symbol, SymbolsSeparator)
            end

            table.insert(symbols, symbol)
          end

          self[1] = self:new(symbols, 1)
        end,
      },
    },
  },
}
