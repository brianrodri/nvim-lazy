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
---@field src_insert_opts obsidian.note.InsertTextOpts|{}
---@field dst_insert_opts obsidian.note.InsertTextOpts|{}
---@field link_fmt string?
---@field src_buf integer?
---@field src_note obsidian.Note?
---@field dst_note obsidian.Note?
local DEFAULT_LINKED_NOTE_OPTS = {
  src_insert_opts = {
    placement = "bot",
    section = { header = "Outgoing Links", level = 2, on_missing = "create" },
  },
  dst_insert_opts = {
    placement = "bot",
    section = { header = "Incoming Links", level = 2, on_missing = "create" },
  },
  link_fmt = "- %s",
}

---@param ... {}|my.obsidian.LinkedNoteOpts
function Vault:new_linked_note(...)
  local obsidian_api = require("obsidian.api")
  local obsidian_unique = require("obsidian.unique")

  local opts = vim.tbl_deep_extend("keep", {}, ..., DEFAULT_LINKED_NOTE_OPTS)
  local src_note = opts.src_note or obsidian_api.current_note(opts.src_buf or 0)
  local dst_note = opts.dst_note or obsidian_unique.new_unique_note(nil, { should_write = true })
  assert(src_note, "src_note must be provided")
  assert(dst_note, "dst_note must be provided")

  local dst_link = opts.link_fmt:format(dst_note:format_link())
  local src_lnum = src_note:insert_text(dst_link, opts.src_insert_opts)
  assert(src_lnum > 0, "Failed to insert link into source note")

  local buf_pos = vim.api.nvim_buf_call(src_note.bufnr, function() return vim.fn.getpos(".") end)
  if buf_pos[1] == src_note.bufnr then
    buf_pos[2] = src_lnum
    buf_pos[3] = dst_link:len() + 1
    local item = { tagname = dst_note.id, from = buf_pos }
    vim.fn.settagstack(vim.fn.bufwinid(opts.src_buf), { items = { item } }, "t")
  end

  dst_note:open({
    callback = vim.schedule_wrap(function()
      local src_link = opts.link_fmt:format(src_note:format_link())
      local dst_lnum = dst_note:insert_text(src_link, opts.dst_insert_opts)
      assert(dst_lnum > 0, "Failed to insert link into destination note")
      local dst_col = src_link:len() + 1
      vim.schedule(function() dst_note:open({ line = dst_lnum, col = dst_col }) end)
    end),
  })
end

local M = {}

function M.new(opts)
  local self = setmetatable(opts or {}, { __index = Vault })
  self.root = vim.fs.normalize(vim.fn.expand(self.root or ""))
  return self
end

return M
