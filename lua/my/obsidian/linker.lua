local M = {}
local H = {}

---@type my.obsidian.linker.LinkOpts
local DEFAULT_LINK_OPTS = {
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

---@type table<string, fun(callback: fun(note?: obsidian.Note))>
local AUTO_RESOLVE = {}

---@param ... my.obsidian.linker.LinkOpts
function M.new(...)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_LINK_OPTS), ...)

  H.resolve_note(opts.src_note, function(src_note)
    H.resolve_note(opts.dst_note, function(dst_note)
      assert(tostring(src_note.path) ~= tostring(dst_note.path), "Source and Destination must be different")

      local link_to_dst_note = opts.link_fmt:format(dst_note:format_link())
      local src_lnum = src_note:insert_text(link_to_dst_note, opts.src_insert_opts)
      assert(src_lnum > 0, "Source could not be changed")

      local src_buf = src_note.bufnr or -1
      local src_win = src_buf > 0 and vim.fn.bufwinid(src_buf) or src_buf
      if src_buf ~= -1 and src_win ~= -1 then
        local src_col = link_to_dst_note:len() + 1
        local src_pos = { src_buf, src_lnum, src_col, 0 }
        vim.fn.settagstack(src_win, { items = { { tagname = dst_note.id, from = src_pos } } }, "t")
      end

      dst_note:open({
        sync = true,
        callback = function()
          local link_to_src_note = opts.link_fmt:format(src_note:format_link())
          local dst_lnum = dst_note:insert_text(link_to_src_note, opts.dst_insert_opts)
          assert(dst_lnum > 0, "Destination could not be changed")

          local dst_col = link_to_src_note:len() + 1
          vim.schedule(function() dst_note:open({ sync = true, line = dst_lnum, col = dst_col }) end)
        end,
      })
    end)
  end)
end

---@param arg? my.obsidian.linker.ResolveNoteOpts
---@param callback fun(note: obsidian.Note)
function H.resolve_note(arg, callback)
  local callback_unless_nil = function(opt_note)
    if opt_note then callback(opt_note) end
  end

  if type(arg) == "number" then
    callback_unless_nil(require("obsidian.api").current_note(arg))
  elseif type(arg) == "string" then
    local func = assert(AUTO_RESOLVE[arg], string.format("unknown strategy: %q", arg))
    func(callback_unless_nil)
  else ---@cast arg obsidian.Note|?
    callback_unless_nil(arg)
  end
end

function AUTO_RESOLVE.named(callback) require("obsidian.actions").new(nil, callback) end
function AUTO_RESOLVE.unique(callback) callback(require("obsidian.actions").unique_note()) end

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
