---@class my.obsidian_ext.Vault
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
local Vault = {}

function Vault:exists()
  local stat = vim.uv.fs_stat(self.root)
  return stat and stat.type == "directory"
end

function Vault:get_workspace_spec()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@diagnostic disable-next-line: missing-fields
    overrides = {
      daily_notes = { folder = self.daily_notes_folder, workdays_only = false, default_tags = {} },
      attachments = { folder = self.attachments_folder },
      frontmatter = { enabled = function(rel_path) return vim.fs.dirname(rel_path) == self.fleeting_notes_folder end },
      note_id_func = function(title, path)
        local builtin = require("obsidian.builtin")
        return string.format("%s-%s", os.time(), builtin.title_id(title, path))
      end,
      ---@diagnostic disable-next-line: missing-fields
      templates = { folder = self.templates_folder },
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
    },
  }
end

local M = {}

function M.new(opts)
  local self = setmetatable(opts or {}, { __index = Vault })
  self.root = vim.fs.normalize(self.root or "")
  return self
end

return M
