local note_ext = require("my.obsidian.note_ext")

---@class my.obsidian.Bookmark
---@field note? obsidian.Note
local Bookmark = {}

function Bookmark:open_or_pick()
  local obsidian_note = require("obsidian.note")
  local obsidian_picker = require("obsidian.picker")

  if not self.note then
    obsidian_picker.find_notes({
      callback = function(path)
        local ok, picked = pcall(obsidian_note.from_file, path)
        if ok and picked then
          self.note = picked
          self.note:open({ sync = true })
        end
      end,
    })
  else
    self.note:open({ sync = true })
  end
end

---@param bufnr? integer
function Bookmark:toggle_buffer(bufnr)
  local obsidian_api = require("obsidian.api")

  local buf_note = obsidian_api.current_note(bufnr)
  if buf_note and self.note and note_ext.equal(buf_note, self.note) then
    self.note = nil
  else
    self.note = buf_note
  end
end

function Bookmark:append_text()
  local obsidian_api = require("obsidian.api")

  if not self.note then return end
  local ok, input = pcall(obsidian_api.input, "Append:")
  local text = vim.trim(ok and input or "")
  if text == "" then return end
  self.note:write({ update_content = function(lines) return vim.list_extend(lines, { text }) end })
end

local M = {}

---@return my.obsidian.Bookmark
function M.new() return setmetatable({}, { __index = Bookmark }) end

return M
