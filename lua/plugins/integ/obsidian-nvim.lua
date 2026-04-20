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
  BROAD_SECTION = { insert_opts = { section = { header = "Broader" } } },
  NARROW_SECTION = { insert_opts = { section = { header = "Narrower" } } },
  RECENT_FILTER = { filter = { cwd = tostring(VAULT.root) } },
}

function H.now() return os.date("%Y-%m-%d %H:%M") end
function H.make_narrow() H.links_between(OPTS.CREATE, { src = OPTS.NARROW_SECTION, dst = OPTS.BROAD_SECTION }) end
function H.make_broad() H.links_between(OPTS.CREATE, { src = OPTS.BROAD_SECTION, dst = OPTS.NARROW_SECTION }) end
function H.pick_narrow() H.links_between(OPTS.PICKER, { src = OPTS.NARROW_SECTION, dst = OPTS.BROAD_SECTION }) end
function H.pick_broad() H.links_between(OPTS.PICKER, { src = OPTS.BROAD_SECTION, dst = OPTS.NARROW_SECTION }) end
function H.links_between(...) my_links.insert_cross_references(vim.tbl_deep_extend("error", {}, ...)) end

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
            { "<leader>vj", function() H.pick_narrow() end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() H.pick_broad() end, desc = "Make Broader Note", buffer = buf },
            { "<leader>vJ", function() H.make_narrow() end, desc = "Pick Narrower Note", buffer = buf },
            { "<leader>vK", function() H.make_broad() end, desc = "Pick Broader Note", buffer = buf },
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
