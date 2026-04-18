local my_utils = require("my.obsidian.utils")

local M = {}
local H = {}
local C = {}

---@param opts? my.obsidian.links.LinkOpts
function M.between(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(C.DEFAULT_LINK_OPTS), opts or {})
  H.resolve_strategy(opts.src.note, function(src_note)
    if not src_note then return end
    H.resolve_strategy(opts.dst.note, function(dst_note)
      if not dst_note or my_utils.is_equal(src_note, dst_note) then return end
      local src_pos = H.insert_link(src_note, dst_note, opts.src.insert_opts)
      local dst_pos = H.insert_link(dst_note, src_note, opts.dst.insert_opts)
      H.push_tagstack_item(dst_note.id, src_pos)
      vim.schedule(function() dst_note:open({ sync = true, line = dst_pos[2], col = dst_pos[3] }) end)
    end)
  end)
end

---@param arg? my.obsidian.links.ResolveNoteOpts
---@param func fun(note: obsidian.Note)
function H.resolve_strategy(arg, func)
  local resolve = function(note)
    if note then func(note) end
  end

  if type(arg) == "number" then
    resolve(require("obsidian.api").current_note(arg))
  elseif type(arg) == "string" then
    local builtin_resolver = assert(C.BUILTIN_RESOLVERS[arg], "invalid value: " .. arg)
    builtin_resolver(resolve)
  else ---@cast arg -string|integer
    resolve(arg)
  end
end

---@param note_mut obsidian.Note
---@param link_target obsidian.Note
---@param opts obsidian.note.InsertTextOpts
---@return [number, number, number, number] pos as returned by |getpos()| (`bufnr`, `line`, `col`, `off`).
function H.insert_link(note_mut, link_target, opts)
  local text = C.LINK_FMT:format(link_target:format_link())
  local line = require("obsidian.note").from_file(note_mut.path):insert_text(text, opts)
  assert(line > 0, "Failed to insert text")
  return { note_mut.bufnr or -1, line, text:len() + 1, 0 }
end

---@param jump_id? string
---@param jump_pos [number, number, number, number] as returned by |getpos()| (`bufnr`, `line`, `col`, `off`).
function H.push_tagstack_item(jump_id, jump_pos)
  local buf = jump_pos[1] or -1
  if buf < 0 then return end
  local win = (buf < 0 and -1) or (buf > 0 and vim.fn.bufwinid(buf)) or 0
  if win < 0 then return end
  vim.fn.settagstack(win, { items = { { tagname = jump_id, from = jump_pos } } }, "t")
end

C.LINK_FMT = "- %s"

---@type table<string, fun(func: fun(note?: obsidian.Note))>
C.BUILTIN_RESOLVERS = {
  picker = function(func) require("obsidian.picker").find_notes({ callback = func, no_default_mappings = true }) end,
  create = function(func) require("obsidian.actions").new(nil, func) end,
  unique = function(func) func(require("obsidian.actions").unique_note()) end,
}

---@type my.obsidian.links.LinkOpts
C.DEFAULT_LINK_OPTS = {
  src = {
    note = 0,
    insert_opts = { placement = "bot", section = { header = "Outgoing Links", level = 2, on_missing = "create" } },
  },
  dst = {
    note = "create",
    insert_opts = { placement = "bot", section = { header = "Incoming Links", level = 2, on_missing = "create" } },
  },
}

--- Resolve a note by predefined strategy name (string), buffer number (integer), or explicit note.
---@alias my.obsidian.links.ResolveNoteOpts
---| string
---| integer
---| obsidian.Note

---@class my.obsidian.links.NoteOpts
---@field note? my.obsidian.links.ResolveNoteOpts|{}
---@field insert_opts? obsidian.note.InsertTextOpts|{}

---@class my.obsidian.links.LinkOpts
---@field src? my.obsidian.links.NoteOpts|{}
---@field dst? my.obsidian.links.NoteOpts|{}

return M
