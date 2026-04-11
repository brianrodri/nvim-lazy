local my_vault = require("my.vault")

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },

    config = my_vault.obsidian_config,
    enabled = my_vault.obsidian_is_enabled(),
    opts = my_vault.obsidian_opts,
    keys = my_vault.obsidian_keys,
  },
}
