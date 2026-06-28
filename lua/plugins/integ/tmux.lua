---@param direction "left" | "right" | "top" | "bottom"
local function tmux_aware_move(direction)
  local tmux = require("tmux")
  local move = assert(tmux["move_" .. direction])
  assert(pcall(move))
end

return {
  {
    "aserowy/tmux.nvim",
    opts = { navigation = { enable_default_keybindings = false } },
    keys = {
      { "<c-h>", function() tmux_aware_move("left") end, desc = "tmux move left" },
      { "<c-j>", function() tmux_aware_move("bottom") end, desc = "tmux move bottom" },
      { "<c-k>", function() tmux_aware_move("top") end, desc = "tmux move top" },
      { "<c-l>", function() tmux_aware_move("right") end, desc = "tmux move right" },
    },
  },
}
