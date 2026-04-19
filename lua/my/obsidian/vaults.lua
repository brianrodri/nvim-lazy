local my_utils = require("my.obsidian.utils")

local M = {}
local H = {}

---@class my.obsidian.Vault: my.obsidian.VaultOpts
local Vault = {}

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
      daily_notes = {
        folder = self.daily_notes_folder,
        workdays_only = false,
        default_tags = {},
        template = "daily-note",
      },
      attachments = { folder = self.attachments_folder },
      frontmatter = {
        enabled = function(p) return require("obsidian.path").new(self.fleeting_notes_folder):is_parent_of(p) end,
        func = function(n)
          local builtin = require("obsidian.builtin").frontmatter(n)
          return vim.tbl_deep_extend("force", {}, self.frontmatter_defaults(n), builtin, self.frontmatter_overrides(n))
        end,
        sort = self.frontmatter_sort,
      },
      note_id_func = H.note_id_func,
      ---@type obsidian.config.TemplateOpts|{}
      templates = { folder = self.templates_folder },
      notes_subdir = tostring(self.fleeting_notes_folder),
      new_notes_location = "notes_subdir",
    },
  }
end

---@param opts my.obsidian.VaultOpts
function M.new(opts)
  ---@type my.obsidian.Vault
  local self = setmetatable(vim.tbl_extend("force", {}, opts), { __index = Vault })
  self.root = my_utils.resolve_path(self.root) or ""
  return self
end

function H.note_id_func(...) return string.format("%s-%s", os.time(), require("obsidian.builtin").title_id(...)) end

function H.plugin_frontmatter(note) return require("obsidian.builtin").frontmatter(note) end

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
