# 🗺️ Hoja de Ruta y Mejoras Futuras (Future Improvements)

Este documento sirve como registro y planificación de posibles mejoras, nuevos plugins y funcionalidades a incorporar en la configuración de Neovim a medio y largo plazo. 

Cada propuesta incluye su **propósito**, **impacto en el flujo de trabajo**, **nivel de esfuerzo** y **evaluación de riesgo/seguridad** (especialmente relevante para equipos en entornos corporativos).

---

## 📊 Matriz de Evaluación Rápida

| Área | Propuesta | Prioridad | Nivel de Riesgo |
| :--- | :--- | :---: | :---: |
| **Inteligencia** | Treesitter (Resaltado estructural completo) | 🟢 Alta | 🟢 Nulo (Código local) |
| **Navegación** | Migrar de NERDTree a `oil.nvim` | 🟢 Alta | 🟢 Nulo (Open Source estándar) |
| **Git** | Integración con Lazygit (`lazygit.nvim`) | 🟡 Media | 🟢 Nulo (Usa binario local `lg`) |
| **Notas / Diario** | Sinergia con `Documentos\Notes` y Markdown | 🟢 Alta | 🟢 Nulo (Lua nativo) |
| **Formateo** | Migrar de `neoformat` a `conform.nvim` | 🟡 Media | 🟢 Nulo |
| **Inteligencia** | LSP básico (`nvim-lspconfig`) | 🟡 Media | 🟡 Bajo (Configuración) |
| **Inteligencia** | Gestor de binarios `mason.nvim` | ⚪ Opcional | 🔴 Medio (Descargas binarias externas) |
| **Completado** | Motor de autocompletado (`blink.cmp` o `nvim-cmp`) | 🟡 Media | 🟢 Nulo |
| **Sesiones** | Restauración de buffers y proyectos (`persistence.nvim`) | ⚪ Baja | 🟢 Nulo |

---

## 1. 🌳 Resaltado Estructural y Sintaxis Avanzada (Treesitter)

- [ ] **Configuración activa de `nvim-treesitter`**
  - **Estado actual:** El plugin está descargado en disco como dependencia de `debugprint.nvim`, pero no tiene activado el módulo de resaltado ni parsers compilados.
  - **Mejora:** Crear `lua/config/treesitter.lua` con:
    ```lua
    require("nvim-treesitter.configs").setup {
        ensure_installed = { "lua", "vim", "vimdoc", "sql", "powershell", "json", "markdown", "markdown_inline" },
        highlight = { enable = true },
        indent = { enable = true },
    }
    ```
  - **Beneficio:** Resaltado de sintaxis mucho más preciso y contextual que las expresiones regulares tradicionales de Vim.
  - **Riesgo:** **Nulo**. No requiere conexiones de red tras la compilación de los parsers con el compilador C (`gcc`).

---

## 2. 🗂️ Navegación y Gestión de Ficheros Moderna (`oil.nvim`)

- [ ] **Sustituir `scrooloose/nerdtree` por [`stevearc/oil.nvim`](https://github.com/stevearc/oil.nvim)**
  - **Estado actual:** NERDTree es un plugin histórico en Vimscript que ocupa espacio visual en un split lateral.
  - **Mejora:** `oil.nvim` permite editar el sistema de archivos **como si fuera un buffer normal de texto**:
    - Cambiar el nombre de un archivo = editar la línea y guardar con `:w`.
    - Eliminar un archivo = borrar la línea con `dd`.
    - Mover archivos = cortar y pegar la línea en otra carpeta.
    - Crear archivo nuevo = añadir una línea nueva con `o` y escribir el nombre.
  - **Atajo propuesto:** `-` para abrir el directorio padre en cualquier momento.
  - **Riesgo:** **Nulo**.

---

## 3. 🌿 Integración con Lazygit (`lazygit.nvim`)

- [ ] **Apertura de Lazygit en ventana flotante**
  - **Plugin:** [`kdheepak/lazygit.nvim`](https://github.com/kdheepak/lazygit.nvim)
  - **Atajo propuesto:** `<Leader>gg`
  - **Beneficio:** En tu perfil de PowerShell utilizas activamente `lazygit` (`lg`). Con este plugin puedes invocarlo dentro de Neovim en una ventana emergente flotante, hacer commits, stashes, ramas o push y, al salir con `q`, volver inmediatamente al archivo que estabas editando.
  - **Riesgo:** **Nulo**. Utiliza el ejecutable local de `lazygit` que ya tienes instalado en el sistema.

---

## 4. 📝 Sinergia con tu Sistema de Notas y Perfil de PowerShell

- [ ] **Atajos directos para el flujo de notas (`$HOME\Documentos\Notes`)**
  - **Abrir nota del día (`<Leader>nt`)**: Script Lua equivalente al comando `note` / `today` de tu PowerShell profile:
    ```lua
    vim.keymap.set("n", "<Leader>nt", function()
        local date = os.date("%Y%m%d")
        local path = vim.fn.expand("$HOME/Documentos/Notes/" .. date .. ".md")
        vim.cmd("edit " .. path)
    end, { desc = "Abrir nota de hoy" })
    ```
  - **Buscar en las notas (`<Leader>fn`)**: Búsqueda difusa restringida exclusivamente a la carpeta de notas usando Telescope:
    ```lua
    vim.keymap.set("n", "<Leader>fn", function()
        require("telescope.builtin").find_files({
            prompt_title = "Buscar Notas",
            cwd = vim.fn.expand("$HOME/Documentos/Notes"),
        })
    end, { desc = "Buscar en notas personales" })
    ```
  - **Alternar casillas de tareas Markdown (`<Leader>x`)**:
    Alterna rápidamente entre `- [ ]` y `- [x]` en la línea actual para gestionar listas de tareas sin escribirlo a mano.

---

## 5. 🧠 Servidores de Lenguaje (LSP) y Autocompletado

- [ ] **LSP nativo y controlado (`neovim/nvim-lspconfig`)**
  - Configurar servidores de lenguaje puntuales sin gestores automáticos invasivos (ej. para Lua, PowerShell o SQL).
  - Atajos estándar:
    - `gd`: Ir a la definición del símbolo.
    - `K`: Mostrar documentación flotante bajo el cursor.
    - `<Leader>ca`: Acciones de código (*Code Actions* / QuickFix).
    - `<Leader>rn`: Renombrar variable en todo el proyecto.
- [ ] **Motor de Autocompletado**
  - Evaluar [`saghen/blink.cmp`](https://github.com/Saghen/blink.cmp) (escrito en Rust, ultrarrápido y sin dependencias pesadas) frente a `hrsh7th/nvim-cmp`.
  - Proporciona sugerencias predictivas de palabras clave, nombres de funciones y snippets mientras se escribe.

---

## 6. ⚡ Formateo Automático Moderno (`conform.nvim`)

- [ ] **Migrar de `sbdchd/neoformat` a [`stevearc/conform.nvim`](https://github.com/stevearc/conform.nvim)**
  - **Motivo:** `conform.nvim` es el estándar moderno en Lua para formateo de código en Neovim:
    - Ejecución asíncrona (no congela el editor mientras formatea archivos grandes).
    - Formateo automático opcional al guardar (`format_on_save`).
    - Compatible con `stylua` (Lua), `sql-formatter` (SQL), `prettier` (JSON/Markdown), etc.

---

## 7. 💾 Restauración de Sesiones (`persistence.nvim`)

- [ ] **Guardar y recuperar estado de trabajo**
  - **Plugin:** [`folke/persistence.nvim`](https://github.com/folke/persistence.nvim)
  - **Beneficio:** Al abrir Neovim en una carpeta de proyecto, permite restaurar con un atajo (`<Leader>qs`) todos los buffers, splits y pestañas tal como los dejaste al cerrar.
