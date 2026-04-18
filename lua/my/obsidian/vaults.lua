local my_utils = require("my.obsidian.utils")

local M = {}
local H = {}

---@class my.obsidian_ext.Vault
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
---@field frontmatter_sort string[]
---@field frontmatter fun(note: obsidian.Note): table<string, any>
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
        enabled = function(path) return require("obsidian.path").new(self.fleeting_notes_folder):is_parent_of(path) end,
        func = function(note) return vim.tbl_deep_extend("keep", self.frontmatter(note), H.plugin_frontmatter(note)) end,
        sort = self.frontmatter_sort,
      },
      note_id_func = H.note_id_func,
      ---@type obsidian.config.TemplateOpts|{}
      templates = { folder = self.templates_folder, date_format = "YYYY-MM-DD", time_format = "HH:mm" },
      notes_subdir = tostring(self.fleeting_notes_folder),
      new_notes_location = "notes_subdir",
    },
  }
end

---@param opts my.obsidian_ext.VaultOpts
function M.new(opts)
  local self = setmetatable({}, { __index = Vault })
  self.name = opts.name
  self.root = my_utils.normalized(opts.root) or ""
  self.fleeting_notes_folder = opts.fleeting_notes_folder
  self.daily_notes_folder = opts.daily_notes_folder
  self.attachments_folder = opts.attachments_folder
  self.templates_folder = opts.templates_folder
  self.frontmatter_sort = opts.frontmatter_sort
  self.frontmatter = opts.frontmatter_extras
  return self
end

function H.note_id_func(...) return string.format("%s-%s", os.time(), require("obsidian.builtin").title_id(...)) end

function H.plugin_frontmatter(note) return require("obsidian.builtin").frontmatter(note) end

---@class my.obsidian_ext.VaultOpts
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
---@field frontmatter_extras fun(note: obsidian.Note): table<string, any>
---@field frontmatter_sort string[]

return M
