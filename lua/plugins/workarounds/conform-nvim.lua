---@module "lazy"
---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    lazy = false,
    -- NOTE: Ensures that the formatter runs with the correct CWD to find the correct config file.
    opts = { formatters = { mdformat = { cwd = require("conform.util").root_file({ ".mdformat.toml" }) } } },
  },
}
