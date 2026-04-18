local bookmarks = require("my.obsidian_ext.bookmarks")
local links = require("my.obsidian_ext.links")
local vaults = require("my.obsidian_ext.vaults")

local VAULT = vaults.new({
  name = "My Vault",
  root = "~/Vault",
  daily_notes_folder = "01-journal/01-daily",
  fleeting_notes_folder = "02-fleeting",
  attachments_folder = "09-meta/attachments",
  templates_folder = "09-meta/templates/obsidian-nvim",
})

local OPTS = {
  CREATE = { dst = { note = "create" } },
  PICKER = { dst = { note = "picker" } },
  BROAD_SECTION = { insert_opts = { section = { header = "Broader" } } },
  NARROW_SECTION = { insert_opts = { section = { header = "Narrower" } } },
  RECENT_FILTER = { filter = { cwd = tostring(VAULT.root) } },
}

local function links_between(...) links.between(vim.tbl_deep_extend("force", {}, ...)) end
local function make_narrow(...) links_between(OPTS.CREATE, { src = OPTS.NARROW_SECTION, dst = OPTS.BROAD_SECTION }, ...) end
local function make_broad(...) links_between(OPTS.CREATE, { src = OPTS.BROAD_SECTION, dst = OPTS.NARROW_SECTION }, ...) end
local function pick_narrow(...) links_between(OPTS.PICKER, { src = OPTS.NARROW_SECTION, dst = OPTS.BROAD_SECTION }, ...) end
local function pick_broad(...) links_between(OPTS.PICKER, { src = OPTS.BROAD_SECTION, dst = OPTS.NARROW_SECTION }, ...) end

local BOOKMARK = bookmarks.new()

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    commit = "d6c0e5bc30937df0657c9953d135d0ebb3af7e00",
    dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim", "folke/snacks.nvim" },
    enabled = VAULT:exists(),
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
          local link_opts = { src = { note = buf } }
          require("which-key").add({
            { "<leader>vp", function() BOOKMARK:toggle_buffer(buf) end, desc = "Pick Bookmark", buffer = buf },
            { "<leader>vj", function() pick_narrow(link_opts) end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() pick_broad(link_opts) end, desc = "Make Broader Note", buffer = buf },
            { "<leader>vJ", function() make_narrow(link_opts) end, desc = "Pick Narrower Note", buffer = buf },
            { "<leader>vK", function() make_broad(link_opts) end, desc = "Pick Broader Note", buffer = buf },
          })
        end,
      })
    end,
    keys = {
      { "<leader>vn", ":Obsidian new<cr>", desc = "New Note" },
      { "<leader>vs", ":Obsidian search<cr>", desc = "Grep Notes" },
      { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Notes" },
      { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian" },
      { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract Note", mode = { "n", "v" } },
      { "<leader>vt", ":Obsidian today<cr>", desc = "Daily Note" },
      { "<leader>vv", function() BOOKMARK:open_or_pick() end, desc = "Open Bookmark" },
      { "<leader>va", function() BOOKMARK:append_text() end, desc = "Append To Bookmark" },
      { "<leader>vr", function() require("snacks.picker").recent(OPTS.RECENT_FILTER) end, desc = "Recent Notes" },
    },
  },
}
