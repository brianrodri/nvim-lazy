---@module "lazy"
---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    commit = "619363c",
    opts = {
      formatters = {
        mdformat = { cwd = require("conform.util").root_file({ ".mdformat.toml" }) },
      },
    },
  },
}
