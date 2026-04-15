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
    "obsidian-nvim/obsidian.nvim",
    commit = "f816915e0bf2f60f44d23a5e3d59658fa8a20094",
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
          local link_opts = { src_note = args.buf } ---@type my.obsidian.linker.LinkOpts
          require("which-key").add({
            buffer = args.buf,
            { "<leader>vp", function() BOOKMARK:toggle_buffer(args.buf) end, desc = "Pick Bookmark" },
            { "<leader>vj", function() linker.new(link_opts, NARROW_OPTS) end, desc = "Make Narrower Note" },
            { "<leader>vk", function() linker.new(link_opts, BROADEN_OPTS) end, desc = "Make Broader Note" },
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
