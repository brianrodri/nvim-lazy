local function open(path)
  if vim.bo.filetype == "minifiles" then return end
  require("mini.files").open(path, true)
end

local function open_in_split(split_direction)
  local MiniFiles = require("mini.files")

  local cur_win_id = MiniFiles.get_explorer_state().target_window
  local new_win_id = vim.api.nvim_win_call(cur_win_id, function()
    vim.cmd(split_direction .. " split")
    return vim.api.nvim_get_current_win()
  end)
  MiniFiles.set_target_window(new_win_id)
  MiniFiles.go_in({ close_on_file = true })
end

return {
  {
    "nvim-mini/mini.files",
    opts = {
      mappings = { go_in = "", go_out = "", reset = "<esc>" },
      windows = { preview = true, width_preview = 80 },
    },
    keys = {
      { "_", function() open(vim.uv.cwd()) end, desc = "Open mini.files (cwd)" },
      { "-", function() open(vim.api.nvim_buf_get_name(0)) end, desc = "Open mini.files (Directory of Current File)" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(event)
          local buf_id = event.data.buf_id
          local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc, buffer = buf_id }) end
          map("<C-l>", function() open_in_split("belowright vertical") end, "Open To Right")
          map("<C-j>", function() open_in_split("belowright horizontal") end, "Open To Bottom")
          map("<C-k>", function() open_in_split("aboveleft horizontal") end, "Open To Top")
          map("<C-h>", function() open_in_split("aboveleft vertical") end, "Open To Left")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event) require("snacks.rename").on_rename_file(event.data.from, event.data.to) end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionDelete",
        callback = function(event) require("snacks.bufdelete").delete({ file = event.data.from }) end,
      })
    end,
  },
}
