-- Macro recording component
return {
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
