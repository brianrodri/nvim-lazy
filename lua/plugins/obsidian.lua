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
  templates_folder = "9. Meta/Templates/obsidian-nvim",
})

local OPTS = {
  ---@type my.obsidian_ext.links.LinkOpts
  MAKE_BROAD = {
    src = { insert_opts = { section = { header = "Broader", level = 2 } } },
    dst = {
      note = "create",
      insert_opts = { template = "fleeting-note", section = { header = "Narrower", level = 2 } },
    },
  },
  ---@type my.obsidian_ext.links.LinkOpts
  MAKE_NARROW = {
    src = { insert_opts = { section = { header = "Narrower", level = 2 } } },
    dst = {
      note = "create",
      insert_opts = { template = "fleeting-note", section = { header = "Broader", level = 2 } },
    },
  },
  ---@type my.obsidian_ext.links.LinkOpts
  PICK_BROAD = {
    src = { insert_opts = { section = { header = "Broader", level = 2 } } },
    dst = {
      note = "picker",
      insert_opts = { template = "fleeting-note", section = { header = "Narrower", level = 2 } },
    },
  },
  ---@type my.obsidian_ext.links.LinkOpts
  PICK_NARROW = {
    src = { insert_opts = { section = { header = "Narrower", level = 2 } } },
    dst = {
      note = "picker",
      insert_opts = { template = "fleeting-note", section = { header = "Broader", level = 2 } },
    },
  },
  ---@type snacks.picker.recent.Config
  PICK_RECENT = { filter = { cwd = VAULT.root } },
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
          local src_link_to = function(...) links.between({ src = { note = buf } }, ...) end
          require("which-key").add({
            { "<leader>vp", function() BOOKMARK:toggle_buffer(buf) end, desc = "Pick Bookmark", buffer = buf },
            { "<leader>vj", function() src_link_to(OPTS.MAKE_NARROW) end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() src_link_to(OPTS.MAKE_BROAD) end, desc = "Make Broader Note", buffer = buf },
            { "<leader>vJ", function() src_link_to(OPTS.PICK_NARROW) end, desc = "Pick Narrower Note", buffer = buf },
            { "<leader>vK", function() src_link_to(OPTS.PICK_BROAD) end, desc = "Pick Broader Note", buffer = buf },
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
      { "<leader>vr", function() require("snacks.picker").recent(OPTS.PICK_RECENT) end, desc = "Recent Notes" },
      { "<leader>vv", function() BOOKMARK:open_or_pick() end, desc = "Open Bookmark" },
      { "<leader>va", function() BOOKMARK:append_text() end, desc = "Append To Bookmark" },
    },
  },
}
