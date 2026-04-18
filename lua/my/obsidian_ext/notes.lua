local M = {} -- PUBLIC API
local C = {} -- CONSTANTS

---@param note1 obsidian.Note
---@param note2 obsidian.Note
function M.is_equal(note1, note2) return M.normalized(note1.path) == M.normalized(note2.path) end

---@param path? string|obsidian.Path
function M.normalized(path)
  if not path then return nil end
  path = tostring(path)
  if not C.CACHE[path] then C.CACHE[path] = vim.fs.normalize(path) end
  return C.CACHE[path]
end

---@type table<string, string>
C.CACHE = {}

return M
