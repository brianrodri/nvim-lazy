local MyObsidianUtils = require("my.obsidian.utils")

local M = {}
local H = {}
local C = {}

--- Inserts bi-directional links between two notes `src` and `dst`.
--- The `src` note is typically the "current" note, and the `dst` note is typically the "destination" note.
--- After insertion, we jump away from the current position and onto the first line of the `dst` note.
---@param opts? my.obsidian.links.LinkOpts
function M.insert_cross_references(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(C.DEFAULT_LINK_OPTS), opts or {})
  H.resolve_note(opts.src.note, function(fwd_note)
    if not fwd_note then return end
    H.resolve_note(opts.dst.note, function(rev_note)
      if not rev_note or MyObsidianUtils.is_equal(fwd_note, rev_note) then return end
      fwd_note:insert_text(C.REFERENCE_LINK_FORMAT_STR:format(rev_note:format_link()), opts.src.insert_opts)
      rev_note:insert_text(C.REFERENCE_LINK_FORMAT_STR:format(fwd_note:format_link()), opts.dst.insert_opts)
      vim.fn.settagstack(0, { items = { { tagname = vim.fn.expand("<cword>"), from = vim.fn.getpos(".") } } }, "t")
      local rev_note_frontmatter_end = require("obsidian.note").from_file(rev_note.path).frontmatter_end_line or 0
      rev_note:open({ line = rev_note_frontmatter_end + 1, col = 1, callback = vim.notify })
    end)
  end)
end

---@type fun(strategy?: my.obsidian.links.ResolveNoteStrategy, on_resolved: my.obsidian.links.ResolveNoteCallback)
function H.resolve_note(strategy, on_resolved)
  if not strategy then
    on_resolved(nil)
    return
    ---@cast strategy -nil
  end

  if type(strategy) == "number" then
    on_resolved(require("obsidian.api").current_note(strategy))
    return
    ---@cast strategy -integer
  end

  if type(strategy) == "string" then
    local resolver = C.NOTE_RESOLVERS[strategy]
    if vim.is_callable(resolver) then
      resolver(on_resolved)
      return
    end
    ---@cast strategy -string
  end

  if type(strategy) == "function" or vim.is_callable(strategy) then
    strategy(on_resolved)
    return
    ---@cast strategy -my.obsidian.links.ResolveNoteImpl
  end

  if require("obsidian.note").is_note_obj(strategy) then
    on_resolved(strategy)
    return
    ---@cast strategy - obsidian.Note
  end

  error("not a strategy name, buffer id, or note: " .. vim.inspect(strategy))
end

C.REFERENCE_LINK_FORMAT_STR = "- %s"

---@type table<string, my.obsidian.links.ResolveNoteImpl>
C.NOTE_RESOLVERS = {
  create = function(on_resolved) require("obsidian.actions").new(nil, on_resolved) end,
  unique = function(on_resolved) on_resolved(require("obsidian.actions").unique_note()) end,
  picker = function(on_resolved) require("obsidian.picker").find_notes({ callback = on_resolved }) end,
}

---@type my.obsidian.links.LinkOpts
C.DEFAULT_LINK_OPTS = {
  src = {
    note = 0,
    insert_opts = { padding_top = true, section = { header = "Outgoing Links", level = 2, on_missing = "create" } },
  },
  dst = {
    note = "create",
    insert_opts = { padding_top = true, section = { header = "Incoming Links", level = 2, on_missing = "create" } },
  },
}

---@alias my.obsidian.links.ResolveNoteCallback
---| fun(note?: obsidian.Note)

---@alias my.obsidian.links.ResolveNoteImpl
---| fun(on_resolved: my.obsidian.links.ResolveNoteCallback)

---@alias my.obsidian.links.ResolveNoteStrategy
---| "create"
---| "unique"
---| "picker"
---| integer
---| obsidian.Note
---| my.obsidian.links.ResolveNoteImpl

---@class my.obsidian.links.NoteOpts
---@field note my.obsidian.links.ResolveNoteStrategy
---@field insert_opts obsidian.note.InsertTextOpts|{}

---@class my.obsidian.links.LinkOpts
---@field src? my.obsidian.links.NoteOpts|{}
---@field dst? my.obsidian.links.NoteOpts|{}

return M
