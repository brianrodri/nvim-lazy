local M = {}

---@class my.Vault: my.VaultOpts
---@field bookmark obsidian.Note|?
local Vault = {}
Vault.__index = Vault

---@class my.VaultOpts
local MyVaultOpts = {
  name = "My Vault",
  root = "~/Vault",
  fleeting_notes_folder = "2. Fleeting",
  daily_notes_folder = "1. Journal/1. Daily",
  attachments_folder = "9. Meta/Attachments",
  templates_folder = "9. Meta/Templates",
}

---@param opts? my.VaultOpts|{}
function Vault.new(opts)
  local self = setmetatable(opts and vim.fn.copy(opts) or {}, Vault)
  self.bookmark = nil
  return self
end

function Vault:enabled() return require("obsidian.path").new(vim.fs.normalize(self.root)):is_dir() end

function Vault:into_workspace()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@type obsidian.config|{}
    overrides = {
      daily_notes = { folder = self.daily_notes_folder, workdays_only = false, default_tags = {} },
      attachments = { folder = self.attachments_folder },
      templates = { folder = self.templates_folder }, ---@type obsidian.config.TemplateOpts|{}
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
      frontmatter = { enabled = function(path) return vim.fs.dirname(path) == self.fleeting_notes_folder end },
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

---@param bufnr? number
---@param on_picked? fun(note?: obsidian.Note, old_note?: obsidian.Note): ...
function Vault:pick_bookmark(bufnr, on_picked)
  local set_bookmark = function(note) self:_set_bookmark(note, on_picked) end
  local current_note = require("obsidian.api").current_note(bufnr)
  if current_note == nil then
    require("obsidian.picker").find_files({
      prompt_title = "Pick Bookmark",
      callback = function(path) set_bookmark(require("obsidian.note").from_file(path)) end,
    })
  elseif not self:_is_bookmark(current_note) then
    set_bookmark(current_note)
  else
    set_bookmark(nil)
  end
end

function Vault:open_bookmark()
  if self.bookmark then
    self.bookmark:open({ sync = true })
  else
    self:pick_bookmark(0, function(note) return note and note:open({ sync = true }) end)
  end
end

function Vault:append_to_bookmark()
  if not self.bookmark then return end
  local input = vim.trim(require("obsidian.api").input("Input:") or "")
  if input == "" then return end
  self.bookmark:write({ update_content = function(lines) return vim.list_extend(lines, { input }) end })
end

---@private
function Vault:_is_bookmark(note)
  if not self.bookmark or not note then return false end
  return tostring(self.bookmark.path) == tostring(note.path)
end

---@private
function Vault:_set_bookmark(note, on_changed)
  note = note and note:exists() and note or nil
  if note == nil and self.bookmark == nil then return end
  if note ~= nil and self.bookmark ~= nil and tostring(note.path) == tostring(self.bookmark.path) then return end
  local old_bookmark = self.bookmark
  self.bookmark = note
  print("Bookmark set to " .. tostring(self.bookmark))
  if on_changed then pcall(on_changed, self.bookmark, old_bookmark) end
end

---

local PRIMARY_VAULT = Vault.new(MyVaultOpts)
local H = {}

M.is_enabled = function() return PRIMARY_VAULT:enabled() end
M.into_workspace = function() return PRIMARY_VAULT:into_workspace() end

M.open_bookmark = function() PRIMARY_VAULT:open_bookmark() end
M.pick_bookmark = function() PRIMARY_VAULT:pick_bookmark(0) end
M.append_to_bookmark = function() PRIMARY_VAULT:append_to_bookmark() end

M.pick_recent_note = function() PRIMARY_VAULT:pick_recent_note() end
M.make_broader_note = function(bufnr) H.newly_linked_note(bufnr, "Broader", "Narrower") end
M.make_narrower_note = function(bufnr) H.newly_linked_note(bufnr, "Narrower", "Broader") end

function H.newly_linked_note(bufnr, fwd, inv)
  local buf_note = require("obsidian.api").current_note(bufnr)
  if not buf_note then return end
  local new_note = require("obsidian.note").create({ id = require("obsidian.api").input("ID (optional):") }):write({
    template = Obsidian.opts.note.template,
    update_content = function(l) return vim.list_extend(l, { "", "## " .. inv, "", "- " .. buf_note:format_link() }) end,
  })
  H.push_location_onto_tagstack(
    new_note.id,
    buf_note:insert_text("- " .. new_note:format_link(), { section = { header = fwd, level = 2 } })
  )
  new_note:open({ line = 4 + (new_note.frontmatter_end_line or 0), col = 3 })
end

function H.push_location_onto_tagstack(tagname, line_num)
  if line_num == 0 then return end
  local buf = vim.api.nvim_get_current_buf()
  local col = 3
  local off = 0
  local new_item = { tagname = tagname, from = { buf, line_num, col, off } }
  vim.fn.settagstack(vim.fn.win_getid(), { items = { new_item } }, "t")
end

return M
