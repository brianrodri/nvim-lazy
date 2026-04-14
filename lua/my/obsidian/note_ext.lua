local M = {}

---@type table<string, string>
local NORMALIZED_PATH_CACHE = {}

---@param path? string|obsidian.Path
local function normalized(path)
  if not path then return nil end
  path = tostring(path)
  if not NORMALIZED_PATH_CACHE[path] then NORMALIZED_PATH_CACHE[path] = vim.fs.normalize(path) end
  return NORMALIZED_PATH_CACHE[path]
end

---@param note1 obsidian.Note
---@param note2 obsidian.Note
function M.equal(note1, note2) return normalized(note1.path) == normalized(note2.path) end

return M
