local M = {} -- PUBLIC API
local C = {} -- CONSTANTS

function M.format_func_call(func_name, ...)
  return string.format("%s(%s)", func_name, vim.iter({ ... }):map(vim.inspect):join(", "))
end

---@param note1 obsidian.Note
---@param note2 obsidian.Note
function M.is_equal(note1, note2) return M.resolve_path(note1.path) == M.resolve_path(note2.path) end

---@param path? string|obsidian.Path
function M.resolve_path(path)
  if not path then return nil end
  path = tostring(path)
  if not C.CACHE[path] then C.CACHE[path] = vim.fs.normalize(path) end
  return C.CACHE[path]
end

--- Truncates the history of `CTRL-T` jumps currently in the |tagstack| and replaces with a new `CTRL-]` jump.
---
---@param current_location [number, number, number, number] as if returned by |getpos|: `[bufnum, lnum, col, off]`.
---@param destination? obsidian.Note The note we're jumping into.
---@param winnum? integer The window where the jump will occur. Defaults to `0` (the current window).
function M.push_tagstack_truncating_jump_from_note(current_location, destination, winnum)
  if not current_location or not destination then return end
  winnum = winnum or 0
  if winnum < 0 then return end
  local bufnum = current_location[1] or -1
  if bufnum < 0 then return end
  vim.fn.settagstack(winnum, { items = { { tagname = vim.fn.expand("<cword>"), from = current_location } } }, "t")
end

---@type table<string, string>
C.CACHE = {}

return M
