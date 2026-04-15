local note_ext = require("my.obsidian.note_ext")

---@class my.obsidian.LinkedNoteOpts
---@field link_fmt string?
---@field src_buf integer?
---@field src_note obsidian.Note?
---@field src_insert_opts obsidian.note.InsertTextOpts|{}
---@field dst_note obsidian.Note?
---@field dst_insert_opts obsidian.note.InsertTextOpts|{}

---@type my.obsidian.LinkedNoteOpts
local DEFAULT_OPTS = {
  link_fmt = "- %s",
  src_buf = nil,
  src_note = nil,
  src_insert_opts = {
    placement = "bot",
    section = { header = "Outgoing Links", level = 2, on_missing = "create" },
  },
  dst_note = nil,
  dst_insert_opts = {
    placement = "bot",
    section = { header = "Incoming Links", level = 2, on_missing = "create" },
  },
}

local M = {}

---@param ... {}|my.obsidian.LinkedNoteOpts
function M.between(...)
  local obsidian_api = require("obsidian.api")
  local obsidian_unique = require("obsidian.unique")

  local opts = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_OPTS), ...)

  local src_note = opts.src_note or obsidian_api.current_note(opts.src_buf or 0)
  assert(src_note, "Failed to resolve source note")
  local dst_note = opts.dst_note or obsidian_unique.new_unique_note(nil, { should_write = true })
  assert(dst_note, "Failed to resolve destination note")
  assert(not note_ext.equal(src_note, dst_note), "Refused to create self-referential link")

  local link_to_dst_note = opts.link_fmt:format(dst_note:format_link())
  local src_col = link_to_dst_note:len() + 1
  local src_line = src_note:insert_text(link_to_dst_note, opts.src_insert_opts)
  assert(src_line > 0, "Failed to insert link into source note")

  local src_win = vim.fn.bufwinid(src_note.bufnr)
  if src_win > -1 then
    local new_item = { tagname = dst_note.id, from = { src_note.bufnr, src_line, src_col, 0 } }
    vim.fn.settagstack(src_win, { items = { new_item } }, "t")
  end

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

return M
