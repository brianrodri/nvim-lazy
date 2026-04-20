local MyObsidianUtils = require("my.obsidian.utils")

local M = {}
local H = {}
local C = {}

---@param opts? my.obsidian.links.LinkOpts
function M.insert_cross_references(opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(C.DEFAULT_LINK_OPTS), opts or {})
  H.resolve_strategy(vim.tbl_get(opts, "src", "note"), function(fwd_note)
    if not fwd_note then return end
    H.resolve_strategy(vim.tbl_get(opts, "dst", "note"), function(rev_note)
      if not rev_note or MyObsidianUtils.is_equal(fwd_note, rev_note) then return end
      local fwd_link_pos = H.insert_link(fwd_note, rev_note, opts.src.insert_opts)
      local rev_link_pos = H.insert_link(rev_note, fwd_note, opts.dst.insert_opts)

      -- As if I pressed `CTRL-]` on the newly-created link to navigate into the destination note.
      MyObsidianUtils.push_tagstack_truncating_jump_from_note(fwd_link_pos, rev_note)

      -- When I press `CTRL-T` after navigating to the destination, then the cursor will return to aforementioned link.
      vim.schedule(function() rev_note:open({ sync = true, line = rev_link_pos[2], col = rev_link_pos[3] }) end)
    end)
  end)
end

---@param strategy? my.obsidian.links.ResolveStrategy
---@param user_callback fun(note?: obsidian.Note)
function H.resolve_strategy(strategy, user_callback)
  if type(strategy) == "number" then
    user_callback(require("obsidian.api").current_note(strategy))
  elseif type(strategy) == "string" then
    local strategy_impl = C.STRATEGY_CALLBACKS[strategy]
    assert(vim.is_callable(strategy_impl), "not a strategy: " .. strategy)
    strategy_impl(user_callback)
  else ---@cast strategy -integer|string
    user_callback(strategy)
  end
end

---@param note_to_change obsidian.Note
---@param destination obsidian.Note
---@param opts obsidian.note.InsertTextOpts
---@return [number, number, number, number] insert_position |getpos| list for the new link: `[bufnum, lnum, col, off]`.
function H.insert_link(note_to_change, destination, opts)
  local text = C.LINK_FMT:format(destination:format_link())
  local line = require("obsidian.note").from_file(note_to_change.path):insert_text(text, opts)
  assert(line > 0, "Failed to insert text")
  return { note_to_change.bufnr or -1, line, text:len() + 1, 0 }
end

C.LINK_FMT = "- %s"

---@type table<string, fun(func: fun(note?: obsidian.Note))>
C.STRATEGY_CALLBACKS = {
  create = function(func) require("obsidian.actions").new(nil, func) end,
  unique = function(func) func(require("obsidian.actions").unique_note()) end,
  picker = function(func) require("obsidian.picker").find_notes({ callback = func, no_default_mappings = true }) end,
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

---@alias my.obsidian.links.ResolveStrategy
---| "create"
---| "unique"
---| "picker"
---| integer
---| obsidian.Note

---@class my.obsidian.links.NoteOpts
---@field note? my.obsidian.links.ResolveStrategy|{}
---@field insert_opts? obsidian.note.InsertTextOpts|{}

---@class my.obsidian.links.LinkOpts
---@field src? my.obsidian.links.NoteOpts|{}
---@field dst? my.obsidian.links.NoteOpts|{}

return M
