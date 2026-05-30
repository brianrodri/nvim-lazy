---@module "lazy"
---@type LazySpec
return {
  {
    "nvim-neotest/neotest",
    dependencies = { { "nvim-neotest/neotest-jest", lazy = false } },
    opts = function(_, opts)
      local jest_adapter = require("neotest-jest")({
        jestCommand = "npm test --",
        jestArguments = function(defaultArguments, _) return defaultArguments end,
        env = { CI = true },
        cwd = function(_) return vim.fn.getcwd() end,
        isTestFile = require("neotest-jest.util").defaultTestFileMatcher,
      })
      opts = opts or {}
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, jest_adapter)
      return opts
    end,
  },
}
