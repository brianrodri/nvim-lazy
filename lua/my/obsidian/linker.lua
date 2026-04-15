local note_ext = require("my.obsidian.note_ext")

local M = {}
local H = {}
local C = {}

---@param ... my.obsidian.linker.LinkOpts
function M.new(...)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(C.DEFAULT_LINK_OPTS), ...)

  H.resolve_note(opts.src_note, function(src_note)
    if not src_note then return end
    H.resolve_note(opts.dst_note, function(dst_note)
      if not dst_note or note_ext.equal(src_note, dst_note) then return end
      local src_pos = H.insert_link(src_note, opts.link_fmt:format(dst_note:format_link()), opts.src_insert_opts)
      local dst_pos = H.insert_link(dst_note, opts.link_fmt:format(src_note:format_link()), opts.dst_insert_opts)

      H.try_pushing_tagstack_item(dst_note.id, src_pos)
      vim.schedule(function() dst_note:open({ sync = true, line = dst_pos[2], col = dst_pos[3] }) end)
    end)
  end)
end

---@param arg? my.obsidian.linker.ResolveNoteOpts
---@param callback fun(note: obsidian.Note)
function H.resolve_note(arg, callback)
  local safely_callback = function(note) return note and callback(note) or nil end

  if type(arg) == "number" then
    safely_callback(require("obsidian.api").current_note(arg))
  elseif type(arg) == "string" then
    local resolver = assert(C.BUILTIN_RESOLVERS[arg], "invalid value: " .. arg)
    resolver(safely_callback)
  else ---@cast arg -string|integer
    safely_callback(arg)
  end
end

---@param note obsidian.Note
---@param text string
---@param opts obsidian.note.InsertTextOpts
---@param off? integer
---@return [number, number, number, number] pos as returned by |getpos()| (`bufnr`, `line`, `col`, `off`).
function H.insert_link(note, text, opts, off)
  local line = require("obsidian.note").from_file(note.path):insert_text(text, opts)
  assert(line > 0, "Failed to insert text")
  return { note.bufnr or -1, line, text:len() + 1, off or 0 }
end

---@param jump_id? string
---@param jump_pos [number, number, number, number] as returned by |getpos()| (`bufnr`, `line`, `col`, `off`).
function H.try_pushing_tagstack_item(jump_id, jump_pos)
  local buf = jump_pos[1]
  if buf < 0 then return end
  local win = buf == 0 and buf or vim.fn.bufwinid(buf)
  if win < 0 then return end
  vim.fn.settagstack(win, { items = { { tagname = jump_id, from = jump_pos } } }, "t")
end

---@type table<string, fun(callback: fun(note?: obsidian.Note))>
C.BUILTIN_RESOLVERS = {
  named = function(callback) require("obsidian.actions").new(nil, callback) end,
  unique = function(callback) callback(require("obsidian.actions").unique_note()) end,
}

---@type my.obsidian.linker.LinkOpts
C.DEFAULT_LINK_OPTS = {
  link_fmt = "- %s",

  src_note = 0,
  src_insert_opts = {
    placement = "bot",
    section = { header = "Outgoing Links", level = 2, on_missing = "create" },
  },

  dst_note = "named",
  dst_insert_opts = {
    placement = "bot",
    section = { header = "Incoming Links", level = 2, on_missing = "create" },
  },
}

--- Resolve a note by predefined strategy name (string), buffer number (integer), or explicit note.
---@alias my.obsidian.linker.ResolveNoteOpts
---| string
---| integer
---| obsidian.Note

---@class my.obsidian.linker.LinkOpts
---@field link_fmt? string
---@field src_note? my.obsidian.linker.ResolveNoteOpts
---@field src_insert_opts? obsidian.note.InsertTextOpts
---@field dst_note? my.obsidian.linker.ResolveNoteOpts
---@field dst_insert_opts? obsidian.note.InsertTextOpts

return M
