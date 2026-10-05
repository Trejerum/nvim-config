local gs = require("gitsigns")

gs.setup {
  signs = {
    add = { hl = "GitSignsAdd", text = "+", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
    change = { hl = "GitSignsChange", text = "~", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    delete = { hl = "GitSignsDelete", text = "_", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    topdelete = { hl = "GitSignsDelete", text = "‾", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    changedelete = { hl = "GitSignsChange", text = "│", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
  },
  word_diff = true,
  current_line_blame = false, -- Desactivado por defecto para evitar ruido visual
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol", -- Al final de la línea
    delay = 300,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = "   <author>, <author_time:%Y-%m-%d> • <summary>",
  on_attach = function(bufnr)
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navegación de cambios (hunks)
    map("n", "]c", function()
      if vim.wo.diff then
        return "]c"
      end
      vim.schedule(function()
        gs.next_hunk()
      end)
      return "<Ignore>"
    end, { expr = true, desc = "Git: Siguiente hunk" })

    map("n", "[c", function()
      if vim.wo.diff then
        return "[c"
      end
      vim.schedule(function()
        gs.prev_hunk()
      end)
      return "<Ignore>"
    end, { expr = true, desc = "Git: Hunk anterior" })

    -- Acciones sobre hunks
    map("n", "<Leader>hs", gs.stage_hunk, { desc = "Git: Stage hunk actual" })
    map("n", "<Leader>hr", gs.reset_hunk, { desc = "Git: Reset/descartar hunk actual" })
    map("v", "<Leader>hs", function()
      gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") }
    end, { desc = "Git: Stage selección visual" })
    map("v", "<Leader>hr", function()
      gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") }
    end, { desc = "Git: Reset selección visual" })
    map("n", "<Leader>hu", gs.undo_stage_hunk, { desc = "Git: Deshacer último stage hunk" })
    map("n", "<Leader>hS", gs.stage_buffer, { desc = "Git: Stage buffer completo" })
    map("n", "<Leader>hR", gs.reset_buffer, { desc = "Git: Reset buffer completo" })
    map("n", "<Leader>hp", gs.preview_hunk, { desc = "Git: Vista previa flotante del hunk" })
    map("n", "<Leader>hb", function()
      gs.blame_line { full = true }
    end, { desc = "Git: Blame flotante detallado" })
    map("n", "<Leader>hl", gs.toggle_current_line_blame, { desc = "Git: Alternar blame virtual inline" })
    map("n", "<Leader>hd", gs.diffthis, { desc = "Git: Diff nativo contra el índice" })
    map("n", "<Leader>hD", function()
      gs.diffthis("~")
    end, { desc = "Git: Diff contra el commit anterior" })

    -- Text object (permite ih: dih = borrar hunk, yih = copiar hunk, vih = seleccionar)
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Git: Seleccionar hunk (text object)" })
  end,
}

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = "*",
  callback = function()
    vim.cmd [[
      hi GitSignsChangeInline gui=reverse
      hi GitSignsAddInline gui=reverse
      hi GitSignsDeleteInline gui=reverse
    ]]
  end
})
