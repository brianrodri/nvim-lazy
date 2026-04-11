local M = {}
local H = {}
local D = {}

D.ROOT_DIR = "~/Vault"
D.NOTES_SUBDIR = "2. Fleeting"
D.VAULT_NAME = "My Vault"
D.DAILY_NOTES_SUBDIR = "1. Journal/1. Daily"
D.ATTACHMENTS_SUBDIR = "9. Meta/Attachments"
D.TEMPLATES_SUBDIR = "9. Meta/Templates"

---@param opts obsidian.config
function M.obsidian_config(_, opts)
  require("obsidian").setup(opts)
  vim.api.nvim_create_autocmd("User", { pattern = "ObsidianNoteEnter", callback = H.on_obsidian_note_entered })
end

---@return boolean? enabled
function M.obsidian_is_enabled()
  local dir_stat = vim.uv.fs_stat(vim.fs.normalize(D.ROOT_DIR))
  return dir_stat and dir_stat.type == "directory"
end

---@type obsidian.workspace.WorkspaceSpec
M.obsidian_opts = {
  name = D.VAULT_NAME,
  path = D.ROOT_DIR,
  ---@type obsidian.config|{}
  overrides = {
    daily_notes = { folder = D.DAILY_NOTES_SUBDIR, workdays_only = false, default_tags = {} },
    attachments = { folder = D.ATTACHMENTS_SUBDIR },
    templates = { folder = D.TEMPLATES_SUBDIR }, ---@type obsidian.config.TemplateOpts|{}
    notes_subdir = D.NOTES_SUBDIR,
    note_id_func = H.note_id_func,
    new_notes_location = "notes_subdir",
    frontmatter = {
      enabled = H.is_frontmatter_enabled,
    },
  },
}

---@type LazyKeysSpec[]
M.obsidian_keys = {
  { "<leader>vn", ":Obsidian new<cr>", desc = "New Note", silent = true },
  { "<leader>vs", ":Obsidian search<cr>", desc = "Search Notes", silent = true },
  { "<leader>vf", ":Obsidian quick_switch<cr>", desc = "Find Note", silent = true },
  { "<leader>vo", ":Obsidian open<cr>", desc = "Open Obsidian", silent = true },
  { "<leader>vv", H.open_pinned_note, desc = "Open Pinned Note", silent = true },
  { "<leader>va", H.append_to_pinned_note, desc = "Append To Pinned Note", silent = true },
  { "<leader>vp", H.pick_pinned_note, desc = "Pin/Unpin Note", silent = true },
  { "<leader>vy", ":Obsidian extract_note<cr>", desc = "Extract to Note", silent = true, mode = { "n", "v" } },
  { "<leader>vt", ":Obsidian today<cr>", desc = "Today's Note", silent = true },
  { "<leader>vr", H.pick_recent_note, desc = "Recent Notes" },
}

---@param args vim.api.keyset.create_autocmd.callback_args
---@return boolean? delete_after
function H.on_obsidian_note_entered(args)
  -- TODO
end

function H.open_pinned_note() end

function H.append_to_pinned_note() end

function H.pick_pinned_note() end

function H.pick_recent_note() end

--- @param base_id? string
function H.note_id_func(base_id)
  local id_components = vim.split(base_id or "", "[^A-Za-z0-9-_.]")
  table.insert(id_components, 1, os.date("%s"))
  return vim
    .iter(id_components)
    :map(function(part)
      part = vim.trim(part)
      part = vim.fn.trim(part, "-_.")
      if vim.fn.empty(part) == 1 then return nil end
      return string.lower(part)
    end)
    :join("-")
end

---@param path string
---@return boolean
function H.is_frontmatter_enabled(path)
  return vim.startswith(path, vim.fs.normalize(vim.fs.joinpath(D.ROOT_DIR, D.NOTES_SUBDIR)))
end

return M
