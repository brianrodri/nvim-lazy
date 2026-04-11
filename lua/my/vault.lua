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
M.obsidian_workspace = {
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

---@param args vim.api.keyset.create_autocmd.callback_args
---@return boolean? delete_after
function H.on_obsidian_note_entered(args)
  -- TODO
end

function M.open_pinned_note() end

function M.append_to_pinned_note() end

function M.pick_pinned_note() end

function M.pick_recent_note() end

---@param base_id? string
---@return string
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
