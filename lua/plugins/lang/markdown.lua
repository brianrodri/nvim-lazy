---@module "lazy"
---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    ---@type conform.setupOpts
    opts = { formatters = { mdformat = { cwd = require("conform.util").root_file({ ".mdformat.toml" }) } } },
  },

  {
    "mfussenegger/nvim-lint",
    opts = { linters = { ["markdownlint-cli2"] = { append_fname = true, stdin = false } } },
  },
}
