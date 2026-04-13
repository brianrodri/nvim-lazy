local M = {}

local FIELD_ASSERTION_FMT = "%s=%s must have type %s"

---@generic T
---@param tbl? T
---@param types_wanted { [string]: string }
---@return T
function M.assert_types(tbl, types_wanted)
  tbl = tbl or {}
  local errors = {}
  for field, wanted in pairs(types_wanted) do
    local value = vim.tbl_get(tbl, table.unpack(vim.split(field, "%.")))
    if type(value) ~= wanted then
      table.insert(errors, FIELD_ASSERTION_FMT:format(field, vim.inspect(value), wanted))
    end
  end
  table.sort(errors)
  assert(#errors == 0, vim.iter(errors):join("\n"))
  return tbl
end

return M
