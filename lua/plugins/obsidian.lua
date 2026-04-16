local bookmark = require("my.obsidian.bookmark")
local linker = require("my.obsidian.linker")
local vault = require("my.obsidian.vault")

local BOOKMARK = bookmark.new()

local VAULT = vault.new({
  name = "My Vault",
  root = "~/Vault",
  daily_notes_folder = "1. Journal/1. Daily",
  fleeting_notes_folder = "2. Fleeting",
  attachments_folder = "9. Meta/Attachments",
  templates_folder = "9. Meta/Templates",
})

---@type my.obsidian.linker.LinkOpts
local NARROW_OPTS = {
  src_insert_opts = { section = { header = "Narrower", level = 2 } },
  dst_insert_opts = { section = { header = "Broader", level = 2 } },
}

---@type my.obsidian.linker.LinkOpts
local BROADEN_OPTS = {
  src_insert_opts = { section = { header = "Broader", level = 2 } },
  dst_insert_opts = { section = { header = "Narrower", level = 2 } },
}

---@module "lazy"
---@type LazySpec
return {
  {
    "brianrodri/obsidian.nvim",
    commit = "d0c2db162cca839df03c86505c3fbde098f4c630",
    dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim", "folke/snacks.nvim" },
    opts = {
      workspaces = { VAULT:get_workspace_spec() },
      ui = { enable = false },
      -- TODO: Delete after 4.0.0 release
      legacy_commands = false,
    },
    config = function(_, opts)
      require("obsidian").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("MyObsidianKeymaps", { clear = true }),
        pattern = "ObsidianNoteEnter",
        callback = function(args)
          local buf = args.buf
          local l_opts = { src_note = buf }
          require("which-key").add({
            { "<leader>vp", function() BOOKMARK:toggle_buffer(buf) end, desc = "Pick Bookmark", buffer = buf },
            { "<leader>vj", function() linker.new(l_opts, NARROW_OPTS) end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() linker.new(l_opts, BROADEN_OPTS) end, desc = "Make Broader Note", buffer = buf },
          })
        end,
      })
    end,
    enabled = VAULT:exists(),
    keys = {
      { "<leader>vn", ":Obsidian new<cr>", desc = "New Note", silent = true },
      { "<leader>vN", ":Obsidian new<cr><cr>", desc = "New Note", silent = true },
      { "<leader>vs", ":Obsidian search<cr>", desc = "Search Notes", silent = true },
      { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Note", silent = true },
      { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian", silent = true },
      { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract to Note", mode = { "n", "v" }, silent = true },
      { "<leader>vt", ":Obsidian today<cr>", desc = "Today's Note", silent = true },
      { "<leader>vr", function() VAULT:pick_recent() end, desc = "Recent Notes", silent = true },
      { "<leader>vv", function() BOOKMARK:open_or_pick() end, desc = "Open Bookmark", silent = true },
      { "<leader>va", function() BOOKMARK:append_text() end, desc = "Append To Bookmark", silent = true },
    },
  },
}
