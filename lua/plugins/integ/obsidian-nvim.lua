local my_bookmarks = require("my.obsidian.bookmarks")
local my_links = require("my.obsidian.links")
local my_vaults = require("my.obsidian.vaults")

local H = {} -- HELPERS

local BOOKMARK = my_bookmarks.new()

local VAULT = my_vaults.new({
  name = "My Vault",
  root = "~/Vault",
  daily_notes_folder = "01-journal/01-daily",
  fleeting_notes_folder = "02-fleeting",
  attachments_folder = "09-meta/attachments",
  templates_folder = "09-meta/templates/obsidian-nvim",
  frontmatter_defaults = function() return { kind = "memo", ["created-on"] = H.now() } end,
  frontmatter_overrides = function() return { ["updated-on"] = H.now() } end,
  frontmatter_sort = { "id", "kind", "subject", "title", "aliases", "tags", "created-on", "updated-on" },
})

local OPTS = {
  CREATE = { dst = { note = "create" } },
  PICKER = { dst = { note = "picker" } },
  BROADER = { insert_opts = { section = { header = "Broader" } } },
  NARROWER = { insert_opts = { section = { header = "Narrower" } } },
  RECENT_FILTER = { filter = { cwd = tostring(VAULT.root) } },
}

function H.now() return os.date("%Y-%m-%d %H:%M") end
function H.write_xref_links(...) my_links.insert_cross_references(vim.tbl_deep_extend("error", {}, ...)) end
function H.make_narrower_note() H.write_xref_links(OPTS.CREATE, { src = OPTS.NARROWER, dst = OPTS.BROADER }) end
function H.make_broader_note() H.write_xref_links(OPTS.CREATE, { src = OPTS.BROADER, dst = OPTS.NARROWER }) end
function H.pick_narrower_note() H.write_xref_links(OPTS.PICKER, { src = OPTS.NARROWER, dst = OPTS.BROADER }) end
function H.pick_broader_note() H.write_xref_links(OPTS.PICKER, { src = OPTS.BROADER, dst = OPTS.NARROWER }) end

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    commit = "d6c0e5bc30937df0657c9953d135d0ebb3af7e00",
    dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim", "folke/snacks.nvim" },
    lazy = false,
    enabled = VAULT:exists(),
    opts = {
      workspaces = { VAULT:get_workspace_spec() },
      -- See: |render-markdown-info-obsidian.nvim|
      ui = { enable = false },
      -- TODO: Delete after 4.0.0 release
      legacy_commands = false,
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("my.adapters.obsidian.ObsidianKeymaps", { clear = true }),
        pattern = "ObsidianNoteEnter",
        callback = function(args)
          local buf = args.buf
          require("which-key").add({
            { "<leader>vp", function() BOOKMARK:toggle_buffer(buf) end, desc = "Pick Bookmark", buffer = buf },
            { "<leader>vJ", function() H.pick_narrower_note() end, desc = "Pick Narrower Note", buffer = buf },
            { "<leader>vK", function() H.pick_broader_note() end, desc = "Pick Broader Note", buffer = buf },
            { "<leader>vj", function() H.make_narrower_note() end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() H.make_broader_note() end, desc = "Make Broader Note", buffer = buf },
          })
        end,
      })
    end,
    keys = {
      { "<leader>vn", function() pcall(require("obsidian.actions").new) end, desc = "New Note" },
      { "<leader>vs", function() pcall(require("obsidian.picker").grep_notes) end, desc = "Grep Notes" },
      { "<leader>vf", function() pcall(require("obsidian.picker").find_notes) end, desc = "Find Notes" },
      { "<leader>vt", function() require("obsidian.daily").today():open() end, desc = "Daily Note" },
      { "<leader>vv", function() BOOKMARK:open_or_pick() end, desc = "Open Bookmark" },
      { "<leader>va", function() BOOKMARK:append_text() end, desc = "Append To Bookmark" },
      {
        "<leader>vr",
        function() pcall(require("snacks.picker").recent, OPTS.RECENT_FILTER) end,
        desc = "Recent Notes",
      },
    },
  },
}
