---@module "lazy"
---@type LazySpec
return {
  {
    "stevearc/conform.nvim",
    lazy = false,
    ---@type conform.setupOpts
    opts = {
      formatters = {
        mdformat = { cwd = require("conform.util").root_file({ ".mdformat.toml" }) },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      lazy = false,
      ---@module "lint"
      ---@type table<string, lint.Linter|{}>
      linters = { ["markdownlint-cli2"] = { append_fname = true, stdin = false } },
    },
  },
}
