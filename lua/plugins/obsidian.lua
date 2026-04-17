local bookmarks = require("my.obsidian_ext.bookmarks")
local links = require("my.obsidian_ext.links")
local vaults = require("my.obsidian_ext.vaults")

local BOOKMARK = bookmarks.new()

local VAULT = vaults.new({
  name = "My Vault",
  root = "~/Vault",
  daily_notes_folder = "1. Journal/1. Daily",
  fleeting_notes_folder = "2. Fleeting",
  attachments_folder = "9. Meta/Attachments",
  templates_folder = "9. Meta/Templates",
})

---@type my.obsidian_ext.links.LinkOpts
local NARROW_OPTS = {
  src_insert_opts = { section = { header = "Narrower", level = 2 } },
  dst_insert_opts = { section = { header = "Broader", level = 2 } },
}

---@type my.obsidian_ext.links.LinkOpts
local BROAD_OPTS = {
  src_insert_opts = { section = { header = "Broader", level = 2 } },
  dst_insert_opts = { section = { header = "Narrower", level = 2 } },
}

---@type snacks.picker.recent.Config
local RECENT_OPTS = { filter = { cwd = VAULT.root } }

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
          local buf_part = { src_note = buf }
          require("which-key").add({
            { "<leader>vp", function() BOOKMARK:toggle_buffer(buf) end, desc = "Pick Bookmark", buffer = buf },
            { "<leader>vj", function() links.new(buf_part, NARROW_OPTS) end, desc = "Add Narrower Note", buffer = buf },
            { "<leader>vk", function() links.new(buf_part, BROAD_OPTS) end, desc = "Add Broader Note", buffer = buf },
          })
        end,
      })
    end,
    enabled = VAULT:exists(),
    keys = {
      { "<leader>vn", ":Obsidian new<cr>", desc = "New Note" },
      { "<leader>vs", ":Obsidian search<cr>", desc = "Grep Notes" },
      { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Notes" },
      { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian" },
      { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract Note", mode = { "n", "v" } },
      { "<leader>vt", ":Obsidian today<cr>", desc = "Daily Note" },
      { "<leader>vr", function() require("snacks.picker").recent(RECENT_OPTS) end, desc = "Recent Notes" },
      { "<leader>vv", function() BOOKMARK:open_or_pick() end, desc = "Open Bookmark" },
      { "<leader>va", function() BOOKMARK:append_text() end, desc = "Append To Bookmark" },
    },
  },
}
