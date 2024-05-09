local keymap = vim.keymap

-- TELESCOPE mappings
keymap.set('n', '<Leader>tf', '<cmd>Telescope find_files<cr>')
keymap.set('n', '<Leader>tg', '<cmd>Telescope live_grep<cr>')
keymap.set('n', '<Leader>tb', '<cmd>Telescope buffers<cr>')
keymap.set('n', '<Leader>th', '<cmd>Telescope help_tags<cr>')
keymap.set('n', '<Leader>ts', '<cmd>Telescope grep_string<cr>')
keymap.set('n', '<Leader>tr', '<cmd>Telescope resume<cr>')

-- NERDTree mappings
keymap.set('n', '<Leader><TAB>', '<cmd>NERDTreeToggle<cr>')
keymap.set('n', '<Leader>r', '<cmd>NERDTreeFind<cr>')

-- Disable shift + K
keymap.set('n', '<S-k>', '')

-- Reselect the text that has just been pasted, see also https://stackoverflow.com/a/4317090/6064933.
keymap.set("n", "<leader>v", "printf('`[%s`]', getregtype()[0])", {
  expr = true,
  desc = "reselect last pasted area",
})

-- Replace visual selection with text in register, but not contaminate the register,
-- see also https://stackoverflow.com/q/10723700/6064933.
keymap.set("x", "p", '"_c<Esc>p')

-- Move current line up and down
-- keymap.set({ "n", "v" }, "<A-j>", ':m+1<CR>==', { desc = "move line up" })
-- keymap.set({ "n", "v" }, "<A-k>", ':m-2<CR>==', { desc = "move line up" })

vim.api.nvim_set_keymap('v', '<A-j>', ":<C-U>execute 'normal! '<Down>m`>-'<CR>", { noremap = true, silent = true })
