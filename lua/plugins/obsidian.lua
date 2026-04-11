local my_vault = require("my.vault")

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ---@type obsidian.config
    opts = {
      workspaces = { my_vault.obsidian_workspace },
      ui = { enable = false },
    },

    config = my_vault.obsidian_config,
    enabled = my_vault.obsidian_is_enabled(),
    keys = my_vault.obsidian_keys,
  },
}
