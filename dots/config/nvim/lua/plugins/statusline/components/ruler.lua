local conditions = require("heirline.conditions")

-- Ruler component
return {
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
