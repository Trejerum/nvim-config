local opt = vim.opt

-- Numeros de linea hibridos (relativo + absoluto actual)
opt.number = true
opt.relativenumber = true

-- Tabulaciones e indentacion (4 espacios)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smarttab = true
opt.smartindent = true

-- Portapapeles compartido con el sistema operativo
opt.clipboard = "unnamedplus"

-- Historial de 'deshacer' persistente entre sesiones
opt.undofile = true

-- Busqueda inteligente
opt.ignorecase = true  -- Insensible a mayusculas por defecto
opt.smartcase = true   -- Sensible si contiene mayusculas
opt.hlsearch = true    -- Resaltar resultados encontrados
opt.incsearch = true   -- Busqueda incremental al escribir

-- Comportamiento y apertura natural de splits
opt.splitbelow = true  -- Nuevos splits horizontales abajo
opt.splitright = true  -- Nuevos splits verticales a la derecha

-- Contexto visual y margenes de scroll
opt.scrolloff = 8       -- Mantener 8 lineas visibles arriba/abajo al hacer scroll
opt.sidescrolloff = 8   -- Mantener 8 columnas visibles a los lados
opt.signcolumn = "yes"  -- Columna de signos siempre fija para evitar parpadeos
opt.cursorline = true   -- Resaltar visualmente la linea activa
opt.termguicolors = true -- Soporte para colores reales (24-bit True Color)
opt.wrap = false        -- Evitar partir lineas largas automaticamente

-- Rendimiento y tiempos de respuesta
opt.updatetime = 250    -- Tiempo de refresco para GitSigns y CursorHold (ms)
opt.timeoutlen = 300    -- Tiempo de espera para secuencias de teclas (ms)
