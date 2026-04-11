local M = {}
local H = {}

function M.obsidian_config(_, opts)
  require("obsidian").setup(opts)
  vim.api.nvim_create_autocmd("User", { pattern = "ObsidianNoteEnter", callback = H.on_obsidian_note_entered })
end

function M.obsidian_is_enabled()
  -- TODO
  return true
end

M.obsidian_opts = {
  -- TODO
}

M.obsidian_keys = {
  -- TODO
}

function H.on_obsidian_note_entered()
  -- TODO
end

return M
