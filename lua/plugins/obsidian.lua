local my_bookmarks = require("my.obsidian.bookmarks")
local my_links = require("my.obsidian.links")
local my_vaults = require("my.obsidian.vaults")

local H = {} -- HELPERS
local C = {} -- CONSTANTS

local BOOKMARK = my_bookmarks.new()
local VAULT = my_vaults.new({
  name = "My Vault",
  root = "~/Vault",
  daily_notes_folder = "01-journal/01-daily",
  fleeting_notes_folder = "02-fleeting",
  attachments_folder = "09-meta/attachments",
  templates_folder = "09-meta/templates/obsidian-nvim",
  frontmatter_extras = function() return { kind = "memo", ["created-on"] = H.now(), ["updated-on"] = H.now() } end,
  frontmatter_sort = { "id", "kind", "subject", "title", "aliases", "tags", "created-on", "updated-on" },
})

function H.now() return os.date("%Y-%m-%d %H:%M") end
function H.links_between(...) my_links.between(vim.tbl_deep_extend("force", {}, ...)) end
function H.make_narrow(opts) H.links_between(C.CREATE, { src = C.NARROW_SECTION, dst = C.BROAD_SECTION }, opts) end
function H.make_broad(opts) H.links_between(C.CREATE, { src = C.BROAD_SECTION, dst = C.NARROW_SECTION }, opts) end
function H.pick_narrow(opts) H.links_between(C.PICKER, { src = C.NARROW_SECTION, dst = C.BROAD_SECTION }, opts) end
function H.pick_broad(opts) H.links_between(C.PICKER, { src = C.BROAD_SECTION, dst = C.NARROW_SECTION }, opts) end

C.CREATE = { dst = { note = "create" } }
C.PICKER = { dst = { note = "picker" } }
C.BROAD_SECTION = { insert_opts = { section = { header = "Broader" } } }
C.NARROW_SECTION = { insert_opts = { section = { header = "Narrower" } } }
C.RECENT_FILTER = { filter = { cwd = tostring(VAULT.root) } }

---@module "lazy"
---@type LazySpec
return {
  {
    "obsidian-nvim/obsidian.nvim",
    commit = "d6c0e5bc30937df0657c9953d135d0ebb3af7e00",
    dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim", "folke/snacks.nvim" },
    lazy = true,
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
            { "<leader>vj", function() H.pick_narrow(link_opts) end, desc = "Make Narrower Note", buffer = buf },
            { "<leader>vk", function() H.pick_broad(link_opts) end, desc = "Make Broader Note", buffer = buf },
            { "<leader>vJ", function() H.make_narrow(link_opts) end, desc = "Pick Narrower Note", buffer = buf },
            { "<leader>vK", function() H.make_broad(link_opts) end, desc = "Pick Broader Note", buffer = buf },
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
      { "<leader>vr", function() require("snacks.picker").recent(C.RECENT_FILTER) end, desc = "Recent Notes" },
    },
  },
}
