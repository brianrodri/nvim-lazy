---@class my.Vault
---@field name string
---@field root string
---@field notes_subdir string
---@field daily_notes_subdir string
---@field attachments_subdir string
---@field templates_subdir string
---@field bookmark obsidian.Note|?
local Vault = {}

---@return my.Vault
function Vault.new(name, root, opts)
  local self = setmetatable({}, { __index = Vault })
  self.name = name
  self.root = vim.fs.normalize(root)
  self.notes_subdir = opts.notes_subdir
  self.daily_notes_subdir = opts.daily_notes_subdir
  self.attachments_subdir = opts.attachments_subdir
  self.templates_subdir = opts.templates_subdir
  self.bookmark = nil
  return self
end

---@return boolean
function Vault:exists()
  local stat = vim.uv.fs_stat(self.root)
  return stat and stat.type == "directory" or false
end

---@return obsidian.workspace.WorkspaceSpec
function Vault:into_workspace()
  return {
    name = self.name,
    path = self.root,
    ---@type obsidian.config|{}
    overrides = {
      daily_notes = { folder = self.daily_notes_subdir, workdays_only = false, default_tags = {} },
      attachments = { folder = self.attachments_subdir },
      templates = { folder = self.templates_subdir }, ---@type obsidian.config.TemplateOpts|{}
      notes_subdir = self.notes_subdir,
      new_notes_location = "notes_subdir",
      frontmatter = { enabled = function(path) return vim.fs.dirname(path) == self.notes_subdir end },
      note_id_func = function(base_id)
        local id = string.format("%s_%s", os.date("%s"), base_id or "")
        return vim
          .iter(string.gmatch(id, "[A-Za-z0-9%s-_\\.]+"))
          :map(function(s) return string.gsub(s, "[%s-_\\.]+", "") end)
          :filter(function(s) return string.len(s) > 0 end)
          :map(string.lower)
          :join("-")
      end,
    },
  }
end

function Vault:pick_recent_note() require("snacks.picker").recent({ filter = { cwd = self.root } }) end

---@param bufnr? integer
---@param open? boolean
function Vault:pick_bookmark(bufnr, open)
  local current_note = require("obsidian.api").current_note(bufnr)

  if self.bookmark and current_note and self.bookmark.path == current_note.path then
    self.bookmark = nil
    print("Bookmark unset")
    return
  elseif current_note then
    self.bookmark = current_note
    print("Bookmark set")
    if open then self.bookmark:open() end
    return
  else
    require("obsidian.picker").find_files({
      prompt_title = "Pick Bookmark",
      callback = function(path)
        if self.bookmark then return end
        self.bookmark = require("obsidian.note").from_file(path)
        print("Bookmark set")
        if open then self.bookmark:open() end
      end,
    })
  end
end

function Vault:open_bookmark()
  if self.bookmark then
    self.bookmark:open()
  else
    error("Bookmark not set")
  end
end

function Vault:append_to_bookmark()
  assert(self.bookmark, "Bookmark not set")
  local text = vim.trim(require("obsidian.api").input("Input:") or "")
  if text == "" then return end
  self.bookmark:write({ update_content = function(lines) return vim.list_extend(lines, { text }) end })
end

---@param bufnr? integer
function Vault:make_broader_note(bufnr)
  local note = require("obsidian.note").from_buffer(bufnr)
  -- TODO
end

---@param bufnr? integer
function Vault:make_narrower_note(bufnr)
  local note = require("obsidian.note").from_buffer(bufnr)
  -- TODO
end

return Vault.new("My Vault", "~/Vault", {
  notes_subdir = "2. Fleeting",
  daily_notes_subdir = "1. Journal/1. Daily",
  attachments_subdir = "9. Meta/Attachments",
  templates_subdir = "9. Meta/Templates",
})
