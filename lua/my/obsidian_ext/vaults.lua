---@class my.obsidian_ext.Vault
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
local Vault = {}

local VaultMetatable = { __index = Vault }

function Vault:exists()
  local stat = vim.uv.fs_stat(self.root)
  return stat and stat.type == "directory" or false
end

function Vault:get_workspace_spec()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@diagnostic disable-next-line: missing-fields
    overrides = {
      note = { template = "fleeting-note.md" },
      daily_notes = {
        folder = self.daily_notes_folder,
        workdays_only = false,
        default_tags = {},
        template = "daily-note",
      },
      attachments = { folder = self.attachments_folder },
      frontmatter = { enabled = function(rel_path) return vim.fs.dirname(rel_path) == self.fleeting_notes_folder end },
      note_id_func = function(...) return string.format("%s-%s", os.time(), require("obsidian.builtin").title_id(...)) end,
      ---@type obsidian.config.TemplateOpts|{}
      templates = { folder = self.templates_folder },
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
    },
  }
end

local M = {}

---@param opts my.obsidian_ext.Vault
function M.new(opts)
  if M.is_vault_obj(opts) then return opts end
  local self = setmetatable(vim.deepcopy(opts), VaultMetatable)
  self.root = vim.fs.normalize(opts.root)
  return self
end

---@param val unknown
function M.is_vault_obj(val) return getmetatable(val) == VaultMetatable end

return M
