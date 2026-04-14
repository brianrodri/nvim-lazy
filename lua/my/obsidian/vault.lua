local note_ext = require("my.obsidian.note_ext")

---@class my.obsidian.Vault
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
local Vault = {}

function Vault:exists()
  local stat = vim.uv.fs_stat(self.root)
  return stat and stat.type == "directory"
end

function Vault:pick_recent() require("snacks.picker").recent({ filter = { cwd = self.root } }) end

function Vault:get_workspace_spec()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@diagnostic disable-next-line: missing-fields
    overrides = {
      daily_notes = { folder = self.daily_notes_folder, workdays_only = false, default_tags = {} },
      attachments = { folder = self.attachments_folder },
      frontmatter = { enabled = function(rel_path) return vim.fs.dirname(rel_path) == self.fleeting_notes_folder end },
      ---@diagnostic disable-next-line: missing-fields
      templates = { folder = self.templates_folder },
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
    },
  }
end

---@class my.obsidian.LinkedNoteOpts
local DEFAULT_LINKED_NOTE_OPTS = {
  ---@type string?
  link_fmt = "- %s",

  ---@type integer?
  src_buf = nil,
  ---@type obsidian.Note?
  src_note = nil,
  ---@type obsidian.note.InsertTextOpts|{}
  src_insert_opts = {
    placement = "bot",
    section = { header = "Outgoing Links", level = 2, on_missing = "create" },
  },

  ---@type obsidian.Note?
  dst_note = nil,
  ---@type obsidian.note.InsertTextOpts|{}
  dst_insert_opts = {
    placement = "bot",
    section = { header = "Incoming Links", level = 2, on_missing = "create" },
  },
}

---@param ... {}|my.obsidian.LinkedNoteOpts
function Vault:new_linked_note(...)
  local obsidian_api = require("obsidian.api")
  local obsidian_unique = require("obsidian.unique")

  local opts = vim.tbl_deep_extend("keep", {}, ..., DEFAULT_LINKED_NOTE_OPTS)
  local src_note = opts.src_note or obsidian_api.current_note(opts.src_buf or 0)
  local dst_note = opts.dst_note or obsidian_unique.new_unique_note(nil, { should_write = true })
  assert(src_note and dst_note and not note_ext.equal(src_note, dst_note))

  local link_to_dst_note = opts.link_fmt:format(dst_note:format_link())
  local src_col = link_to_dst_note:len() + 1
  local src_line = src_note:insert_text(link_to_dst_note, opts.src_insert_opts)
  assert(src_line > 0, "Failed to insert link into source note")

  local new_tagstack_item = { tagname = dst_note.id, from = { src_note.bufnr, src_line, src_col, 0 } }
  vim.fn.settagstack(vim.fn.bufwinid(src_note.bufnr), { items = { new_tagstack_item } }, "t")

  dst_note:open({
    callback = vim.schedule_wrap(function()
      local link_to_src_note = opts.link_fmt:format(src_note:format_link())
      local dst_col = link_to_src_note:len() + 1
      local dst_line = dst_note:insert_text(link_to_src_note, opts.dst_insert_opts)
      assert(dst_line > 0, "Failed to insert link into destination note")

      vim.schedule(function() dst_note:open({ line = dst_line, col = dst_col }) end)
    end),
  })
end

local M = {}

function M.new(opts)
  local self = setmetatable(opts or {}, { __index = Vault })
  self.root = vim.fs.normalize(self.root or "")
  return self
end

return M
