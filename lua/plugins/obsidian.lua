local my_vault = require("my.vault")

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    commit = "f81691",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = { my_vault:into_workspace() },
      ui = { enable = false },
    },
    config = function(_, opts)
      require("obsidian").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        pattern = "ObsidianNoteEnter",
        callback = function(args)
          require("which-key").add({
            { "<leader>vb", function() my_vault:pick_bookmark(args.buf, false) end, desc = "Pick Bookmark" },
            { "<leader>vj", function() my_vault:make_narrower_note(args.buf) end, desc = "Make Narrower Note" },
            { "<leader>vk", function() my_vault:make_broader_note(args.buf) end, desc = "Make Broader Note" },
          }, { buf = args.buf })
        end,
      })
    end,
    enabled = function() return my_vault:exists() end,
    keys = {
      { "<leader>vn", ":Obsidian new<cr>", desc = "New Note", silent = true },
      { "<leader>vN", ":Obsidian new<cr><cr>", desc = "New Note", silent = true },
      { "<leader>vs", ":Obsidian search<cr>", desc = "Search Notes", silent = true },
      { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Note", silent = true },
      { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian", silent = true },
      { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract to Note", mode = { "n", "v" }, silent = true },
      { "<leader>vt", ":Obsidian today<cr>", desc = "Today's Note", silent = true },
      { "<leader>vr", function() my_vault:pick_recent_note() end, desc = "Recent Notes", silent = true },
      { "<leader>vv", function() my_vault:open_bookmark() end, desc = "Open Bookmark", silent = true },
      { "<leader>va", function() my_vault:append_to_bookmark() end, desc = "Append To Bookmark", silent = true },
    },
  },
}
