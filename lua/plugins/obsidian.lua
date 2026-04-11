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
    keys = {
      { "<leader>vn", ":Obsidian new<cr>", desc = "New Note", silent = true },
      { "<leader>vs", ":Obsidian search<cr>", desc = "Search Notes", silent = true },
      { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Note", silent = true },
      { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian", silent = true },
      { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract to Note", silent = true, mode = { "n", "v" } },
      { "<leader>vt", ":Obsidian today<cr>", desc = "Today's Note", silent = true },
      { "<leader>vr", my_vault.pick_recent_note, desc = "Recent Notes" },
      { "<leader>vv", my_vault.open_pinned_note, desc = "Open Pinned Note", silent = true },
      { "<leader>va", my_vault.append_to_pinned_note, desc = "Append To Pinned Note", silent = true },
      { "<leader>vp", my_vault.pick_pinned_note, desc = "Pin/Unpin Note", silent = true },
    },
  },
}
