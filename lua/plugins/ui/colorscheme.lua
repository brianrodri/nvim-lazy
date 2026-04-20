return {
  {
    "everviolet/nvim",
    name = "evergarden",
    priority = 1000,
    ---@type evergarden.types.config|{}
    opts = {
      theme = { variant = "winter" },
      ---@diagnostic disable-next-line: missing-fields
      editor = { transparent_background = true },
      overrides = function(colors)
        return {
          SnacksDashboardHeader = { fg = colors.green },
          SnacksDashboardIcon = { fg = colors.green },
          SnacksDashboardDesc = { fg = colors.text },
          SnacksDashboardKey = { fg = colors.green },
          SnacksDashboardFooter = { fg = colors.comment },
          SnacksDashboardSpecial = { fg = colors.green },
          SnacksDashboardDir = { fg = colors.comment },
          SnacksDashboardFile = { fg = colors.text },
          SnacksDashboardTerminal = { fg = colors.text },
          SnacksDashboardTitle = { fg = colors.green, style = { "bold" } },
        }
      end,
    },
    config = function(_, opts)
      require("evergarden").setup(opts)
      vim.cmd.colorscheme("evergarden")
    end,
  },
}
