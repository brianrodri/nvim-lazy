return {
  "Mathijs-Bakker/godotdev.nvim",
  config = function(_, opts)
    require("godotdev").setup(opts)
    vim.lsp.enable("gdscript")
  end,
}
