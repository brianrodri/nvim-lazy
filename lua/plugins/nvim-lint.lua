---@module "lazy"
---@type LazySpec
return {
  {
    "mfussenegger/nvim-lint",
    -- `markdownlint-cli2` depends on `fname` for finding the root config file (`.markdownlint.json`).
    opts = { linters = { ["markdownlint-cli2"] = { append_fname = true, stdin = false } } },
  },
}
