local H = {} --- HELPERS
local C = {} --- CONSTANTS

--- MY VAULT API
local API = {}

function API.is_enabled() return C.PRIMARY_VAULT:enabled() end

function API.into_workspace() return C.PRIMARY_VAULT:into_workspace() end

function API.open_bookmark() C.PRIMARY_VAULT:open_bookmark() end

function API.pick_bookmark() C.PRIMARY_VAULT:pick_bookmark(0) end

function API.append_to_bookmark() C.PRIMARY_VAULT:append_to_bookmark() end

function API.pick_recent_note() C.PRIMARY_VAULT:pick_recent_note() end

function API.make_broader_note(bufnr) H.make_bidi_link(bufnr, "Broader", "Narrower") end

function API.make_narrower_note(bufnr) H.make_bidi_link(bufnr, "Narrower", "Broader") end

---@class my.Vault - MY VAULT CLASS
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string
---@field bookmark? obsidian.Note
local Vault = {}
Vault.__index = Vault

---@param opts? my.Vault|{}
function Vault.new(opts)
  opts = opts or {}
  return getmetatable(opts) == Vault and opts or setmetatable(opts, Vault)
end

function Vault:enabled()
  local obsidian_path = require("obsidian.path")

  return obsidian_path.new(vim.fs.normalize(self.root)):is_dir()
end

function Vault:into_workspace()
  ---@type obsidian.workspace.WorkspaceSpec
  return {
    name = self.name,
    path = self.root,
    ---@diagnostic disable-next-line: missing-fields
    overrides = {
      daily_notes = { folder = self.daily_notes_folder, workdays_only = false, default_tags = {} },
      attachments = { folder = self.attachments_folder },
      frontmatter = { enabled = function(path) return vim.fs.dirname(path) == self.fleeting_notes_folder end },
      ---@diagnostic disable-next-line: missing-fields
      templates = { folder = self.templates_folder },
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
      note_id_func = H.note_id_func,
    },
  }
end

function Vault:pick_recent_note()
  local snacks_picker = require("snacks.picker")

  snacks_picker.recent({ filter = { cwd = self.root } })
end

---@param bufnr? number
---@param callback? fun(): ...
function Vault:pick_bookmark(bufnr, callback)
  local obsidian_api = require("obsidian.api")
  local obsidian_note = require("obsidian.note")
  local obsidian_picker = require("obsidian.picker")

  local buf_note = obsidian_api.current_note(bufnr)
  if self:is_bookmarked(buf_note) then
    self:set_bookmarked(nil, callback)
  elseif buf_note then
    self:set_bookmarked(buf_note, callback)
  else
    pcall(obsidian_picker.find_files, {
      prompt_title = "Pick Bookmark",
      callback = function(p) self:set_bookmarked(obsidian_note.from_file(p), callback) end,
    })
  end
end

function Vault:open_bookmark()
  if self.bookmark then
    self.bookmark:open({ sync = true })
  else
    self:pick_bookmark(0, function()
      if self.bookmark then self.bookmark:open({ sync = true }) end
    end)
  end
end

function Vault:append_to_bookmark()
  local obsidian_api = require("obsidian.api")

  if not self.bookmark then return end
  local input = vim.trim(obsidian_api.input("Input:") or "")
  if input == "" then return end
  self.bookmark:write({ update_content = function(lines) return vim.list_extend(lines, { input }) end })
end

---@param note? obsidian.Note
function Vault:is_bookmarked(note) return self.bookmark and note and tostring(self.bookmark.path) == tostring(note.path) end

---@param note? obsidian.Note
---@param on_changed? fun(new_bookmark?: obsidian.Note, old_bookmark?: obsidian.Note): ...
function Vault:set_bookmarked(note, on_changed)
  if note == nil and self.bookmark == nil then return end
  if note ~= nil and self.bookmark ~= nil and tostring(note.path) == tostring(self.bookmark.path) then return end
  local old_bookmark = self.bookmark
  self.bookmark = note
  print(self.bookmark and string.format("Bookmark set to '%s'", self.bookmark.path) or "Bookmark unset")
  if on_changed then on_changed(self.bookmark, old_bookmark) end
end

------------
--- HELPERS
------------

---@param id? string
function H.note_id_func(id)
  id = string.format("%s_%s", os.date("%s"), id or "")
  return vim
    .iter(string.gmatch(id, "[A-Za-z0-9%s-_\\.]+"))
    :map(function(s) return string.gsub(s, "[%s-_\\.]+", "") end)
    :filter(function(s) return string.len(s) > 0 end)
    :map(string.lower)
    :join("-")
end

---@param bufnr? number
---@param fwd string
---@param rev string
function H.make_bidi_link(bufnr, fwd, rev)
  local obsidian_api = require("obsidian.api")
  local obsidian_note = require("obsidian.note")

  local buf_note = obsidian_api.current_note(bufnr)
  if not buf_note then return end

  local new_note = obsidian_note.create({ id = obsidian_api.input("ID (optional):") }):write({
    template = Obsidian.opts.note.template,
    update_content = function(lines)
      return vim.list_extend(lines, { "", "## " .. rev, "", "- " .. buf_note:format_link() })
    end,
  })
  H.push_location_onto_tagstack(
    new_note.id,
    buf_note:insert_text("- " .. new_note:format_link(), { section = { header = fwd, level = 2 } })
  )
  new_note:open({ line = 4 + (new_note.frontmatter_end_line or 0), col = 3 })
end

---@param tagname string
---@param line_num number
function H.push_location_onto_tagstack(tagname, line_num)
  if line_num == 0 then return end
  local buf = vim.api.nvim_get_current_buf()
  local col = 3
  local off = 0
  local new_item = { tagname = tagname, from = { buf, line_num, col, off } }
  vim.fn.settagstack(vim.fn.win_getid(), { items = { new_item } }, "t")
end

--------------
--- CONSTANTS
--------------

C.PRIMARY_VAULT = Vault.new({
  name = "My Vault",
  root = "~/Vault",
  fleeting_notes_folder = "2. Fleeting",
  daily_notes_folder = "1. Journal/1. Daily",
  attachments_folder = "9. Meta/Attachments",
  templates_folder = "9. Meta/Templates",
})

--------
--- EOF
--------

return API
