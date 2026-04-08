return {
  {
    "everviolet/nvim",
    name = "evergarden",
    priority = 1000,
    opts = {
      theme = { variant = "winter" },
      editor = { transparent_background = true },
    },
    config = function(_, opts)
      require("evergarden").setup(opts)
      vim.cmd.colorscheme("evergarden")
    end,
  },
}
