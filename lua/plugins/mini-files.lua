local function open(path)
  if vim.bo.filetype == "minifiles" then return end
  require("mini.files").open(path, true)
end

return {
  {
    "nvim-mini/mini.files",
    keys = {
      { "_", function() open(vim.uv.cwd()) end, desc = "Open mini.files (cwd)" },
      { "-", function() open(vim.api.nvim_buf_get_name(0)) end, desc = "Open mini.files (Directory of Current File)" },
    },
  },
}
