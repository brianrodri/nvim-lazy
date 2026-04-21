local MyObsidianUtils = require("my.obsidian.utils")

local M = {}

---@class my.obsidian.Vault: my.obsidian.VaultOpts
local Vault = {}

---@param opts my.obsidian.VaultOpts
---@return my.obsidian.Vault
function M.new(opts)
  local self = setmetatable(vim.tbl_extend("force", {}, opts), { __index = Vault })
  self.root = MyObsidianUtils.resolve_path(self.root) or ""
  return self
end

---@return boolean
function Vault:exists()
  local stat = vim.uv.fs_stat(self.root)
  return stat and stat.type == "directory" or false
end

---@return obsidian.workspace.WorkspaceSpec
function Vault:resolve_workspace_spec()
  return {
    name = self.name,
    path = self.root,
    overrides = {
      daily_notes = {
        folder = self.daily_notes_folder,
        workdays_only = false,
        default_tags = {},
        template = "daily-note",
      },
      attachments = { folder = self.attachments_folder },
      templates = { folder = self.templates_folder },
      new_notes_location = "notes_subdir",
      notes_subdir = tostring(self.fleeting_notes_folder),
      note_id_func = function(...) return string.format("%s-%s", os.time(), require("obsidian.builtin").title_id(...)) end,
      frontmatter = {
        enabled = function(path) return require("obsidian.path").new(self.fleeting_notes_folder):is_parent_of(path) end,
        func = function(note) return self:resolve_frontmatter(note) end,
        sort = self.frontmatter_sort,
      },
    },
  }
end

---@param note obsidian.Note
---@return table<string, any>
function Vault:resolve_frontmatter(note)
  local as_before = require("obsidian.builtin").frontmatter(note)
  return vim.tbl_deep_extend("force", self.frontmatter_defaults(note), as_before, self.frontmatter_overrides(note))
end

---@class my.obsidian.VaultOpts
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
---@field frontmatter_overrides fun(note: obsidian.Note): table<string, any>
---@field frontmatter_defaults fun(note: obsidian.Note): table<string, any>
---@field frontmatter_sort string[]

return M
