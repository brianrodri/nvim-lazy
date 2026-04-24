---@module "lazy"
---@type LazySpec
return {
  {
    "kawre/leetcode.nvim",
    dependencies = {
      "3rd/image.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "MeanderingProgrammer/render-markdown.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ---@module "leetcode"
    ---@type lc.UserConfig|{}
    opts = { lang = "rust" },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    ---@type my.types.TSConfig
    opts = { ensure_installed = { "html" } },
    opts_extend = { "ensure_installed" },
  },
}
