---@module "lazy"
---@type LazySpec
-- Fix rust-analyzer workspace discovery for LeetCode.nvim Rust solutions.
-- LeetCode.nvim stores standalone .rs files without a Cargo project, so we
-- generate a rust-project.json and configure linkedProjects accordingly.
-- Requires: `rustup component add rust-src`

local leetcode_dir = vim.fn.stdpath("data") .. "/leetcode"
local project_json_path = leetcode_dir .. "/rust-project.json"

local function generate_rust_project_json()
  local files = vim.fn.glob(leetcode_dir .. "/*.rs", false, true)
  if #files == 0 then
    return
  end

  local sysroot = vim.trim(vim.fn.system("rustc --print sysroot"))
  local sysroot_src = sysroot .. "/lib/rustlib/src/rust/library"

  local crates = vim.tbl_map(function(file)
    return { root_module = file, edition = "2021", deps = {} }
  end, files)

  vim.fn.writefile(
    { vim.json.encode({ sysroot_src = sysroot_src, crates = crates }) },
    project_json_path
  )
end

return {
  {
    -- Regenerate rust-project.json whenever a LeetCode Rust buffer is entered.
    "kawre/leetcode.nvim",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = leetcode_dir .. "/*.rs",
        desc = "Regenerate rust-project.json for LeetCode Rust files",
        callback = function()
          local current = vim.api.nvim_buf_get_name(0)
          -- Only regenerate when the file isn't already tracked.
          if vim.fn.filereadable(project_json_path) == 1 then
            local existing = table.concat(vim.fn.readfile(project_json_path))
            if existing:find(current, 1, true) then
              return
            end
          end
          generate_rust_project_json()
          -- Restart rust-analyzer so it picks up the updated linkedProjects.
          vim.schedule(function()
            vim.cmd("LspRestart")
          end)
        end,
      })
    end,
  },

  {
    -- Configure rust-analyzer to use linkedProjects for LeetCode files.
    "mrcjkb/rustaceanvim",
    opts = function(_, opts)
      opts.server = opts.server or {}
      local orig_settings = opts.server.settings

      opts.server.settings = function(project_root, default_settings)
        local settings = {}
        if type(orig_settings) == "function" then
          settings = orig_settings(project_root, default_settings) or {}
        elseif type(orig_settings) == "table" then
          settings = vim.deepcopy(orig_settings)
        end

        if project_root and vim.startswith(project_root, leetcode_dir) then
          settings["rust-analyzer"] = settings["rust-analyzer"] or {}
          settings["rust-analyzer"].linkedProjects = { project_json_path }
        end

        return settings
      end
      return opts
    end,
  },
}
