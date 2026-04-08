-- Directional splits
vim.keymap.set("n", "<leader><C-h>", ":leftabove vsplit<CR>", { desc = "Split Left" })
vim.keymap.set("n", "<leader><C-j>", ":rightbelow split<CR>", { desc = "Split Bottom" })
vim.keymap.set("n", "<leader><C-k>", ":leftabove split<CR>", { desc = "Split Top" })
vim.keymap.set("n", "<leader><C-l>", ":rightbelow vsplit<CR>", { desc = "Split Right" })
