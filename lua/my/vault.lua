local my_utils = require("my.utils")

local M = {} --- MY API
local H = {} --- MY HELPERS
local C = {} --- MY CONSTANTS

function M.is_enabled() return C.PRIMARY_VAULT:exists() end

function M.get_workspace_spec() return C.PRIMARY_VAULT:get_workspace_spec() end

function M.open_bookmark() C.PRIMARY_VAULT:open_bookmark() end

function M.pick_bookmark() C.PRIMARY_VAULT:pick_bookmark(0) end

function M.append_to_bookmark() C.PRIMARY_VAULT:append_to_bookmark() end

function M.pick_recent_note()
  local snacks_picker = require("snacks.picker")
  snacks_picker.recent({ filter = { cwd = C.PRIMARY_VAULT.root } })
end

function M.make_broader_note(bufnr)
  H.insert_bidi_link(require("obsidian.api").current_note(bufnr), "Broader", "Narrower")
end

function M.make_narrower_note(bufnr)
  H.insert_bidi_link(require("obsidian.api").current_note(bufnr), "Narrower", "Broader")
end

---@class my.VaultOpts
---@field name string
---@field root string
---@field fleeting_notes_folder string
---@field daily_notes_folder string
---@field attachments_folder string
---@field templates_folder string

---@class my.Vault : my.VaultOpts
---@field bookmark? obsidian.Note
local Vault = {}
Vault.__index = Vault

---@param opts my.Vault
---@return my.Vault
function Vault.new(opts)
  if getmetatable(opts) == Vault then return opts end
  my_utils.assert_types(opts, {
    name = "string",
    root = "string",
    fleeting_notes_folder = "string",
    daily_notes_folder = "string",
    attachments_folder = "string",
    templates_folder = "string",
  })
  local self = setmetatable(opts, Vault)
  self.root = vim.fs.normalize(opts.root)
  self.bookmark = nil
  return self
end

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
      ---@diagnostic disable-next-line: missing-fields
      templates = { folder = self.templates_folder },
      notes_subdir = self.fleeting_notes_folder,
      new_notes_location = "notes_subdir",
      note_id_func = H.note_id_func,
    },
  }
end

---@param bufnr? number
---@param callback? fun(): ...
function Vault:pick_bookmark(bufnr, callback)
  local obsidian_api = require("obsidian.api")
  local obsidian_note = require("obsidian.note")
  local obsidian_picker = require("obsidian.picker")

  local buf_note = obsidian_api.current_note(bufnr)
  if not buf_note then
    obsidian_picker.find_files({
      prompt_title = "Pick Bookmark",
      callback = function(path) self:set_bookmarked(obsidian_note.from_file(path), callback) end,
    })
  elseif not H.is_same_note(buf_note, self.bookmark) then
    self:set_bookmarked(buf_note, callback)
  else
    self:set_bookmarked(nil, callback)
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
---@param on_changed? fun()
function Vault:set_bookmarked(note, on_changed)
  if H.is_same_note(note, self.bookmark) then return end
  self.bookmark = note
  print(self.bookmark and C.BOOKMARK_SET_FMT:format(self.bookmark.path) or C.BOOKMARK_UNSET_MSG)
  if on_changed then on_changed() end
end

------------
--- HELPERS
------------

---@param id? string
function H.note_id_func(id)
  id = vim.trim(string.format("%s %s", os.time(), id or ""))
  return vim.iter(string.gmatch(id, "([A-Za-z0-9]+)")):map(string.lower):join("-")
end

---@param src_note? obsidian.Note
---@param fwd string
---@param rev string
function H.insert_bidi_link(src_note, fwd, rev)
  local obsidian_api = require("obsidian.api")
  local obsidian_note = require("obsidian.note")

  if not src_note then return end
  local new_note = obsidian_note.create({
    id = obsidian_api.input("ID?:"),
    template = Obsidian.opts.note.template,
    should_write = true,
  })

  local src_note_link = C.LINK_FMT:format(src_note:format_link())
  local new_note_link = C.LINK_FMT:format(new_note:format_link())

  H.push_location_onto_tagstack({
    tagname = new_note.id,
    line = src_note:insert_text(new_note_link, { section = { header = fwd, level = 2 } }),
  })

  new_note:open({
    sync = true,
    callback = function()
      new_note:open({ col = 3, line = new_note:insert_text(src_note_link, { section = { header = rev, level = 2 } }) })
    end,
  })
end

---@param opts { line: number, tagname: string }
function H.push_location_onto_tagstack(opts)
  my_utils.assert_types(opts, { line = "number", tagname = "string" })
  if opts.line <= 0 then return end
  local buf = vim.api.nvim_get_current_buf()
  local col = 3
  local off = 0
  local new_entry = { tagname = tostring(opts.tagname), from = { buf, opts.line, col, off } }
  vim.fn.settagstack(vim.fn.win_getid(), { items = { new_entry } }, "t")
end

---@param lhs? obsidian.Note
---@param rhs? obsidian.Note
function H.is_same_note(lhs, rhs)
  if lhs == nil and rhs == nil then return true end
  return lhs and rhs and tostring(lhs.path) == tostring(rhs.path)
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

C.LINK_FMT = "- %s"
C.WRONG_TYPE_FMT = "field %s=%s must have type '%s'"

C.BOOKMARK_SET_FMT = "Bookmark set to %s"
C.BOOKMARK_UNSET_MSG = "Bookmark unset"

--------
--- EOF
--------

return M
