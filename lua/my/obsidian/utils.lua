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

---@type table<string, string>
C.CACHE = {}

return M
