local my_utils = require("my.obsidian.utils")

local H = {}
local M = {}

---@class my.obsidian.Bookmark
---@field note? obsidian.Note
local Bookmark = {}

function Bookmark:open_or_pick()
  local picker = require("obsidian.picker")
  return H.ensure_open(self.note) or picker.find_notes({ callback = function(p) self.note = H.ensure_open(p) end })
end

---@param bufnr? integer
function Bookmark:toggle_buffer(bufnr)
  local buf_note = require("obsidian.api").current_note(bufnr)
  if buf_note and self.note and my_utils.is_equal(buf_note, self.note) then
    self.note = nil
  else
    self.note = buf_note
  end
end

function Bookmark:append_text()
  if not self.note then return end
  local ok, input = pcall(require("obsidian.api").input, "Append:")
  local text = vim.trim(ok and input or "")
  if text == "" then return end
  self.note:write({ update_content = function(lines) return vim.list_extend(lines, { text }) end })
end

---@param val? obsidian.Note|string
---@return obsidian.Note?
function H.ensure_open(val)
  if not val then return nil end
  if type(val) ~= "string" then val = tostring(val.path) end
  local ok, picked = pcall(require("obsidian.note").from_file, val)
  if ok and picked then picked:open({ sync = true }) end
  return ok and picked or nil
end

---@return my.obsidian.Bookmark
function M.new() return setmetatable({}, { __index = Bookmark }) end

return M
