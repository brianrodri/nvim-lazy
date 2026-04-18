---@class my.obsidian_ext.Vault
---@field name string
---@field root obsidian.Path
---@field fleeting_notes_folder obsidian.Path
---@field daily_notes_folder obsidian.Path
---@field attachments_folder obsidian.Path
---@field templates_folder obsidian.Path
local Vault = {}

local VaultMetatable = { __index = Vault }

function Vault:exists() return self.root:is_dir() end

function Vault:get_workspace_spec()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@diagnostic disable-next-line: missing-fields
    overrides = {
      daily_notes = {
        folder = tostring(self.daily_notes_folder),
        workdays_only = false,
        default_tags = {},
        template = "daily-note",
      },
      attachments = { folder = tostring(self.attachments_folder) },
      frontmatter = {
        enabled = function(vault_path) return self.fleeting_notes_folder:is_parent_of(vault_path) end,
      },
      note_id_func = function(...) return string.format("%s-%s", os.time(), require("obsidian.builtin").title_id(...)) end,
      ---@type obsidian.config.TemplateOpts|{}
      templates = { folder = self.templates_folder, date_format = "YYYY-MM-DD", time_format = "HH:mm" },
      notes_subdir = tostring(self.fleeting_notes_folder),
      new_notes_location = "notes_subdir",
    },
  }
end

local M = {}

---@param opts my.obsidian_ext.VaultOpts
function M.new(opts)
  local Path = require("obsidian.path")

  local self = setmetatable({}, VaultMetatable)
  self.name = opts.name
  self.root = Path.new(opts.root):resolve({ strict = true })
  self.fleeting_notes_folder = self.root / opts.fleeting_notes_folder
  self.daily_notes_folder = self.root / opts.daily_notes_folder
  self.attachments_folder = self.root / opts.attachments_folder
  self.templates_folder = self.root / opts.templates_folder
  return self
end

---@param val unknown
function M.is_vault_obj(val) return getmetatable(val) == VaultMetatable end

---@class my.obsidian_ext.VaultOpts
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string

return M
