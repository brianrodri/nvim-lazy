---@module "lazy"
---@type LazySpec
return {
  {
    "Mathijs-Bakker/godotdev.nvim",
    opts = { inline_hints = { enabled = true } },
    dependencies = { "nvim-dap", "nvim-dap-ui", "nvim-treesitter" },
  },
}
