local M = {}
local H = {}

---@param opts obsidian.config|{}
function M.obsidian_config(_, opts)
  require("obsidian").setup(opts)
  vim.api.nvim_create_autocmd("User", { pattern = "ObsidianNoteEnter", callback = H.on_obsidian_note_entered })
end

---@return boolean? enabled
function M.obsidian_is_enabled()
  -- TODO
  return true
end

---@type obsidian.config|{}
M.obsidian_opts = {
  -- TODO
}

---@type LazyKeys[]
M.obsidian_keys = {
  -- TODO
}

---@param args vim.api.keyset.create_autocmd.callback_args
---@return boolean? delete_after
function H.on_obsidian_note_entered(args)
  -- TODO
end

return M
