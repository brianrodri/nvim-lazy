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

---@type table<string, fun(callback: fun(note?: obsidian.Note)): obsidian.Note|?>
local AUTO_RESOLVE = {}

---@param ... my.obsidian.linker.LinkOpts
function M.new(...)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_LINK_OPTS), ...)

  H.resolve_note(opts.src_note, function(src_note)
    assert(src_note and src_note:exists(), "Source could not be resolved")
    H.resolve_note(opts.dst_note, function(dst_note)
      assert(dst_note and dst_note:exists(), "Destination could not be resolved")
      assert(tostring(src_note.path) ~= tostring(dst_note.path), "Source and Destination must be different")

      local link_to_dst_note = opts.link_fmt:format(dst_note:format_link())
      local src_col = link_to_dst_note:len() + 1
      local src_buf = src_note.bufnr
      local src_lnum = src_note:insert_text(link_to_dst_note, opts.src_insert_opts)
      assert(src_lnum > 0, "Source could not be changed")

      if src_buf == 0 or src_buf == vim.api.nvim_win_get_buf(0) then
        vim.fn.settagstack(0, { items = { { tagname = dst_note.id, from = { src_buf, src_lnum, src_col, 0 } } } }, "t")
      end

      dst_note:open({
        sync = true,
        callback = function()
          local link_to_src_note = opts.link_fmt:format(src_note:format_link())
          local dst_col = link_to_src_note:len() + 1
          local dst_lnum = dst_note:insert_text(link_to_src_note, opts.dst_insert_opts)
          assert(dst_lnum > 0, "Destination could not be changed")

          vim.schedule(function() dst_note:open({ sync = true, line = dst_lnum, col = dst_col }) end)
        end,
      })
    end)
  end)
end

---@param arg? my.obsidian.linker.ResolveNoteOpts
---@param callback fun(note?: obsidian.Note)
function H.resolve_note(arg, callback)
  if type(arg) == "number" then
    callback(require("obsidian.api").current_note(arg))
  elseif type(arg) == "string" then
    local func = assert(AUTO_RESOLVE[arg], string.format("unknown strategy: %q", arg))
    func(callback)
  else ---@cast arg obsidian.Note|?
    callback(arg)
  end
end

function AUTO_RESOLVE.named(callback) require("obsidian.actions").new(nil, callback) end
function AUTO_RESOLVE.unique(callback) callback(require("obsidian.actions").unique_note()) end

---@alias my.obsidian.linker.ResolveNoteOpts
---|string to use a predefined resolution strategy (e.g. "named", "unique").
---|integer to use a specific note from a buffer
---|obsidian.Note to use a specific note

---@class my.obsidian.linker.LinkOpts
---@field link_fmt? string
---@field src_note? my.obsidian.linker.ResolveNoteOpts
---@field src_insert_opts? obsidian.note.InsertTextOpts
---@field dst_note? my.obsidian.linker.ResolveNoteOpts
---@field dst_insert_opts? obsidian.note.InsertTextOpts

return M
