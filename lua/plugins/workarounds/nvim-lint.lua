---@module "lazy"
---@type LazySpec
return {
  {
    "mfussenegger/nvim-lint",
    -- NOTE: Ensures that the linter runs with the correct path to find the correct config file.
    opts = { linters = { ["markdownlint-cli2"] = { append_fname = true, stdin = false } } },
  },
}
