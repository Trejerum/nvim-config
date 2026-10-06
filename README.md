# Neovim & Centro de Edición Developer

Configuración avanzada de **Neovim** escrita íntegramente en **Lua**, modular y gestionada de forma declarativa con [lazy.nvim](https://github.com/folke/lazy.nvim). Diseñada como un entorno de edición y desarrollo de alto rendimiento, ágil, ligero y reproducible al 100% entre diferentes sistemas operativos (**Windows**, **Linux** y **macOS**).

---

## 🚀 Requisitos y Herramientas del Entorno

La configuración aprovecha aceleradores nativos y herramientas de línea de comandos para maximizar la velocidad de búsqueda, edición e indexación:

| Herramienta | Utilidad en el Entorno |
| :--- | :--- |
| **`Neovim` (>= 0.9.0)** | Motor de edición modal moderno con soporte de LuaJIT y Treesitter. |
| **`Git`** | Clonación del repositorio, sincronización y gestor de plugins mediante `lazy.nvim`. |
| **`Ripgrep` (`rg`)** | Motor de búsqueda de texto ultrarrápido utilizado por Telescope (`<Leader>tg`, `<Leader>ts`). |
| **`fd`** | Búsqueda de archivos indexada a nivel de sistema para agilizar Telescope (`<Leader>tf`). |
| **`Compilador C` (`gcc`)** | Compilación nativa de parsers de Treesitter (C#, TypeScript, SQL, HTML). |

---

## 📦 Instalación y Puesta a Punto (`install.ps1`)

El repositorio incluye un script aprovisionador para Windows ([`install.ps1`](install.ps1)) y compatibilidad nativa con sistemas Unix.

### 🪟 Windows (PowerShell)

```powershell
# 1. Clonar el repositorio en la ruta estándar de dotfiles
git clone https://github.com/Trejerum/nvim-config.git "$HOME\.dotfiles\nvim"

# 2. Entrar en el directorio y ejecutar el aprovisionador (crea la unión NTFS automáticamente)
cd "$HOME\.dotfiles\nvim"
.\install.ps1

# 3. Iniciar Neovim
nvim
```

El script [`install.ps1`](install.ps1):
- Comprueba la versión instalada de Neovim en el sistema.
- Verifica la disponibilidad de herramientas clave (`git`, `rg`, `fd`, compiladores C) y sugiere su instalación inmediata mediante `winget`.
- Valida que la ruta de despliegue sea la esperada por Neovim en Windows (`$env:LOCALAPPDATA\nvim`).
- Ejecuta una sincronización desatendida (*headless*) de los plugins con `lazy.nvim`.

### 🐧 Linux / 🍎 macOS (Bash / Zsh)

```bash
# 1. (Opcional) Copia de seguridad si ya existía una configuración previa
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"

# 2. Clonar el repositorio
git clone https://github.com/Trejerum/nvim-config.git "$HOME/.config/nvim"

# 3. Iniciar Neovim (lazy.nvim se instalará e inicializará automáticamente)
nvim
```

---

## 📂 Arquitectura Modular (`lua/`)

La configuración está estructurada en módulos independientes y desacoplados para garantizar un arranque rápido, mantenibilidad sencilla y total compatibilidad con Git:

| Archivo / Directorio | Área | Descripción |
| :--- | :--- | :--- |
| **[`init.lua`](init.lua)** | **Bootstrap & Entrada** | Bootstrap autónomo de `lazy.nvim`, configuración de teclas líder (`<Space>`) y carga ordenada de módulos. |
| **[`lazy-lock.json`](lazy-lock.json)** | **Lockfile Determinista** | Registro estricto de hashes y commits de cada plugin para garantizar idéntico comportamiento en cualquier equipo. |
| **[`lua/opts.lua`](lua/opts.lua)** | **Opciones del Editor** | Parámetros visuales y de indentación: números de línea (`number`), sangría de 4 espacios (`shiftwidth = 4`), tabs inteligentes. |
| **[`lua/globals.lua`](lua/globals.lua)** | **Variables Globales** | Variables de entorno y ajustes globales de plugins (`vim.g.autoformat = false`). |
| **[`lua/mappings.lua`](lua/mappings.lua)** | **Atajos de Teclado** | Atajos personalizados para búsquedas con Telescope, explorador NERDTree, gestión de ventanas y manipulación de registros. |
| **[`lua/plugins.lua`](lua/plugins.lua)** | **Ecosistema de Plugins** | Declaración y especificación de plugins gestionados mediante `lazy.nvim`. |
| **[`lua/config/lualine.lua`](lua/config/lualine.lua)** | **Barra de Estado** | Tema, iconos y secciones dinámicas de la statusline (rama git, diffs, diagnósticos, modo y progreso). |
| **[`lua/config/nvim_hop.lua`](lua/config/nvim_hop.lua)** | **Movimiento Preciso** | Resaltado de colores y mapeo de saltos bidireccionales por parejas de caracteres con Hop. |
| **[`lua/config/gitsigns.lua`](lua/config/gitsigns.lua)** | **Indicadores Git** | Signos de adición/cambio/borrado en el gutter, navegación entre hunks (`]c`/`[c`) e inspección de cambios. |
| **[`lua/config/debugprint.lua`](lua/config/debugprint.lua)** | **Depuración Rápida** | Atajos y comandos para la inserción instantánea de sentencias de depuración por consola. |
| **[`lua/ai/`](lua/ai/)** | **Integración de IA (Opcional)** | Módulo desacoplado para interacción con Antigravity CLI (`agy`) en terminal flotante y análisis de código. |
| **[`docs/future-improvements.md`](docs/future-improvements.md)** | **Hoja de Ruta & Backlog** | Registro de mejoras futuras planificadas, ideas y matriz de evaluación de riesgos. |

---

## 🧭 1. Navegación Ágil y Gestión de Splits

Control fluido del espacio de trabajo y distribución de ventanas divididas:

- **Navegación entre splits:**
  - <kbd>Ctrl + h</kbd>: Mueve el foco a la ventana o split de la **izquierda**.
  - <kbd>Ctrl + j</kbd>: Mueve el foco a la ventana o split **inferior**.
  - <kbd>Ctrl + k</kbd>: Mueve el foco a la ventana o split **superior**.
  - <kbd>Ctrl + l</kbd>: Mueve el foco a la ventana o split de la **derecha**.

- **Redimensionamiento dinámico:**
  - <kbd>Ctrl + ↑</kbd>: Reduce el alto del split activo (`-10`).
  - <kbd>Ctrl + ↓</kbd>: Aumenta el alto del split activo (`+10`).
  - <kbd>Ctrl + ←</kbd>: Reduce el ancho del split activo (`-10`).
  - <kbd>Ctrl + →</kbd>: Aumenta el ancho del split activo (`+10`).

---

## 🔍 2. Búsqueda Difusa y Exploración (Telescope)

Integración con [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) para la localización instantánea de archivos, buffers y patrones de texto. La tecla **Leader** es <kbd>Espacio</kbd>:

| Atajo | Comando | Descripción |
| :--- | :--- | :--- |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>f</kbd> | `:Telescope find_files` | Búsqueda difusa de archivos en todo el árbol del proyecto. |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>g</kbd> | `:Telescope live_grep` | Búsqueda de cadenas de texto en tiempo real con Ripgrep. |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>b</kbd> | `:Telescope buffers` | Listado y conmutación rápida entre buffers abiertos. |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>h</kbd> | `:Telescope help_tags` | Búsqueda en el manual de ayuda integrado de Neovim. |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>s</kbd> | `:Telescope grep_string` | Búsqueda de todas las apariciones de la palabra bajo el cursor. |
| <kbd>Leader</kbd> + <kbd>t</kbd> <kbd>r</kbd> | `:Telescope resume` | Reanuda la última búsqueda de Telescope con su estado y filtros previos. |

---

## 🗂️ 3. Exploración de Archivos (NERDTree)

Navegación visual del árbol de directorios del proyecto mediante [nerdtree](https://github.com/scrooloose/nerdtree):

- **<kbd>Leader</kbd> + <kbd>Tab</kbd>**: Abre o cierra el panel lateral de NERDTree (`:NERDTreeToggle`).
- **<kbd>Leader</kbd> + <kbd>r</kbd>**: Localiza y resalta en el árbol el archivo actualmente abierto en el buffer (`:NERDTreeFind`).

---

## 🐇 4. Movimiento Preciso en Pantalla (Hop)

Saltos directos y sin fricción a cualquier punto de la pantalla mediante [hop.nvim](https://github.com/smoka7/hop.nvim):

- **<kbd>f</kbd>** (Modos Normal, Visual y Operador): Activa el salto bidireccional por pares de caracteres (`hop.hint_char2()`). Pulsa dos caracteres visibles y luego la letra clave asignada por Hop para saltar instantáneamente a esa posición.

---

## 🌿 5. Control de Versiones con Git

Herramientas ágiles y no sobrecargadas para controlar cambios, revisar ramas y auditar código directamente desde el editor:

### 🚀 Operaciones Globales y Navegación Git (`<Leader>g...`)

| Atajo | Comando | Modo | Descripción |
| :--- | :--- | :---: | :--- |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>l</kbd> | `:LazyGit` / `:Lg` | Normal | Abre **Lazygit** en una ventana flotante centrada; sincroniza los buffers al salir con `q`. |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>s</kbd> | `:Telescope git_status` | Normal | Lista difusa interactiva de archivos modificados con vista previa de diff en vivo. |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>c</kbd> | `:Telescope git_commits` | Normal | Historial de commits con autor, fecha, buscador difuso y diff detallado. |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>b</kbd> | `:Telescope git_branches` | Normal | Listado de ramas; pulsa <kbd>Enter</kbd> para cambiar de rama o gestionarlas. |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>g</kbd> | `:Git` | Normal | Panel de staging interactivo de **Fugitive** (pulsa `-` para stage/unstage, `cc` para commit). |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>d</kbd> | `:Gdiffsplit` | Normal | Comparación lado a lado (*side-by-side diff*) del archivo activo contra el índice. |
| <kbd>Leader</kbd> + <kbd>g</kbd> <kbd>p</kbd> | `:Git push` | Normal | Envía los commits locales a la rama remota configurada. |

### 🔍 Gestión Quirúrgica de Cambios y Hunks (`<Leader>h...` - `gitsigns`)

Sin interfaces externas: todas las operaciones ocurren directamente en el archivo en edición:

| Atajo | Modo | Acción |
| :--- | :---: | :--- |
| <kbd>]c</kbd> / <kbd>[c</kbd> | Normal | Salta al **siguiente** / **anterior** bloque de cambios (*hunk*). |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>s</kbd> | Normal / Visual | **Stage hunk**: Añade al commit únicamente el bloque bajo el cursor (o la selección en visual). |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>r</kbd> | Normal / Visual | **Reset hunk**: Descarta/revierte quirúrgicamente solo ese bloque de cambios (o selección). |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>u</kbd> | Normal | **Undo stage**: Deshace el último *staging* realizado sobre un hunk. |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>S</kbd> | Normal | Añade todos los cambios del archivo completo al *staging* (`git add %`). |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>R</kbd> | Normal | Descarta todos los cambios del archivo completo restaurando la versión de Git. |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>p</kbd> | Normal | Muestra una ventana emergente flotante con el diff del bloque sin mover el cursor. |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>b</kbd> | Normal | Muestra un popup flotante con el *blame* detallado (autor, commit, fecha y mensaje). |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>l</kbd> | Normal | **Toggle Blame Inline**: Alterna texto tenue virtual al final de la línea actual. |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>d</kbd> | Normal | Abre un split nativo de dos paneles (`vimdiff`) comparando el archivo contra el índice. |
| <kbd>Leader</kbd> + <kbd>h</kbd> <kbd>D</kbd> | Normal | Abre un split nativo comparando contra el commit anterior (`HEAD~1`). |
| <kbd>i</kbd><kbd>h</kbd> (*text object*) | Operador / Visual | Objeto de texto para manipular hunks (`dih` para borrarlo, `yih` para copiarlo, `vih` para seleccionarlo). |

---

## ✏️ 6. Edición Eficiente y Manipulación de Registros

- **Limpiar resaltado de búsqueda:** Pulsa <kbd>Esc</kbd> en modo normal para desmarcar el resaltado tras buscar palabras.
- **Pegado limpio sin sobreescritura:** En modo visual, al pulsar <kbd>p</kbd> se reemplaza el texto seleccionado sin contaminar el registro predeterminado (`"_c<Esc>p`), permitiendo volver a pegar el contenido original repetidamente.
- **Reselección del bloque pegado:** <kbd>Leader</kbd> + <kbd>v</kbd> vuelve a seleccionar visualmente el último bloque de texto pegado.
- **Movimiento de bloques:** En modo visual, <kbd>Alt + j</kbd> desplaza la selección verticalmente hacia abajo.
- **Comentarios rápidos ([Comment.nvim](https://github.com/numToStr/Comment.nvim)):**
  - `gcc`: Comenta / descomenta la línea actual.
  - `gc` (en modo visual): Comenta / descomenta el bloque seleccionado.
- **Envoltorios de caracteres ([vim-surround](https://github.com/tpope/vim-surround)):**
  - `cs"'`: Cambia comillas dobles por simples.
  - `ysiw)`: Envuelve la palabra actual entre paréntesis.
  - `ds"`: Elimina las comillas circundantes.

---

## 🤖 7. Asistentes de IA Integrados (Antigravity `agy` & OpenAI `codex`)

La configuración incluye un módulo completamente aislado en [`lua/ai/`](lua/ai/) con soporte nativo para dos proveedores CLI sin añadir dependencias externas ni plugins de terceros:
* **Antigravity CLI (`agy`)**: Accesible con los comandos y atajos de prefijo `<Leader>a...`.
* **OpenAI Codex CLI (`codex`)**: Sincronizado con tus hilos de VS Code y accesible con el prefijo `<Leader>c...`.

### 🌌 Antigravity CLI (`<Leader>a...`)

| Atajo | Comando | Modo | Descripción |
| :--- | :--- | :---: | :--- |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>g</kbd> | `:Agy` / `:AgyChat` / `:AiChat` | Normal, Terminal | Abre o alterna la terminal flotante centrada con una sesión interactiva de `agy`. |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>c</kbd> | `:AgyContinue` / `:AiContinue` | Normal, Terminal | Reanuda directamente la última conversación activa (`agy -c`). |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>h</kbd> | `:AgyHistory` / `:AiHistory` | Normal | Historial de conversaciones con buscador difuso en Telescope y vista previa del transcript. |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>e</kbd> | `:AgyExplain` / `:AiExplain` | Normal, Visual | Envía el buffer o la selección a `agy` para obtener una explicación técnica detallada en un split. |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>r</kbd> | `:AgyReview` / `:AiReview` | Normal, Visual | Auditoría de código buscando bugs, seguridad y buenas prácticas. |
| <kbd>Leader</kbd> + <kbd>a</kbd> <kbd>f</kbd> | `:AgyRefactor` / `:AiRefactor` | Normal, Visual | Solicita instrucciones interactivas y genera una propuesta de refactorización en un split. |

### ⚡ OpenAI Codex CLI (`<Leader>c...` / `<Leader>cx...`)

| Atajo | Comando | Modo | Descripción |
| :--- | :--- | :---: | :--- |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>x</kbd> (o <kbd>c</kbd><kbd>g</kbd>) | `:Cx` / `:CodexChat` / `:CxChat` | Normal, Terminal | Abre o alterna la terminal flotante centrada con la sesión interactiva de `codex`. |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>c</kbd> | `:CodexContinue` / `:CxContinue` | Normal, Terminal | Reanuda la última sesión activa de Codex / VS Code (`codex resume --last`). |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>h</kbd> | `:CodexHistory` / `:CxChats` | Normal | Historial de hilos de Codex compartidos con VS Code mediante Telescope y vista previa. |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>r</kbd> | `:CodexReview` / `:CxReview` | Normal, Terminal | Ejecuta la revisión automatizada del repositorio Git con `codex review`. |
| — | `:CodexDoctor` / `:CxDoctor` | Normal, Terminal | Ejecuta el diagnóstico de salud, autenticación y sandbox de Codex. |
| — | `:CodexApply [id]` / `:CxApply [id]` | Normal | Aplica el parche de diff más reciente o por Task ID con `codex apply`. |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>e</kbd> | `:CodexExplain` | Normal, Visual | Explicación técnica de código con el motor de Codex. |
| <kbd>Leader</kbd> + <kbd>c</kbd> <kbd>f</kbd> | `:CodexRefactor` | Normal, Visual | Refactorización de código asistida por Codex con prompt interactivo. |

> **Modo Ephemeral (`--no-daemon`):** Todas las invocaciones de Codex inyectan automáticamente el modificador `--no-daemon` y resuelven dinámicamente el ejecutable empaquetado en VS Code (`~/.vscode/extensions/openai.chatgpt*/bin/`), previniendo el error de paquete local incompleto cuando no se dispone del servicio de background daemon.
> **Alternar proveedor predeterminado:** Usa `:AiProvider [agy|codex]` para cambiar el motor por defecto de los comandos genéricos (`:AiChat`, `:AiExplain`, etc.).
> **Aislamiento y desacoplamiento:** En las terminales flotantes, pulsa <kbd>Esc</kbd><kbd>Esc</kbd> o <kbd>q</kbd> para ocultarlas sin matar la sesión. Para desactivar la IA por completo, basta con comentar la línea `require("ai")` en [`init.lua`](init.lua).

---

## 🔌 8. Ecosistema de Plugins (`lazy.nvim`)

El gestor de plugins utilizado es [lazy.nvim](https://github.com/folke/lazy.nvim). Lista de extensiones incluidas:

| Plugin | Propósito | Estado |
| :--- | :--- | :---: |
| **`folke/lazy.nvim`** | Gestor de plugins moderno, asíncrono y de carga perezosa (*lazy loading*). | Activo |
| **`nvim-telescope/telescope.nvim`** | Buscador difuso modular y extensible. | Activo |
| **`nvim-lua/plenary.nvim`** | Librería de utilidades Lua esencial para plugins modernos. | Activo |
| **`scrooloose/nerdtree`** | Árbol de archivos lateral y visor de directorios. | Activo |
| **`nvim-lualine/lualine.nvim`** | Barra de estado rápida y ligera con soporte de iconos. | Activo |
| **`folke/tokyonight.nvim`** | Esquema de colores moderno y limpio para Neovim. | Activo |
| **`lewis6991/gitsigns.nvim`** | Indicadores de cambios Git en el margen y navegación de hunks. | Activo |
| **`tpope/vim-fugitive`** | Suite integral de integración con Git. | Activo |
| **`kdheepak/lazygit.nvim`** | Integración de Lazygit en ventana flotante con sincronización de buffers. | Activo |
| **`folke/which-key.nvim`** | Popup interactivo que guía y recuerda atajos de teclado pendientes. | Activo |
| **`tpope/vim-surround`** | Manipulación ágil de pares circundantes (comillas, etiquetas, paréntesis). | Activo |
| **`numToStr/Comment.nvim`** | Conmutación potente de comentarios por línea y bloque. | Activo |
| **`smoka7/hop.nvim`** | Motor de navegación y salto visual preciso en pantalla. | Activo |
| **`sbdchd/neoformat`** | Formateador universal de código compatible con múltiples lenguajes. | Activo |
| **`folke/neoconf.nvim`** | Soporte para ajustes de configuración por proyecto local. | Activo |
| **`andrewferrier/debugprint.nvim`** | Inserción automatizada de sentencias de depuración por pantalla. | Activo |
| **`echasnovski/mini.nvim`** | Colección de módulos utilitarios para Neovim. | Activo |
| **`nvim-treesitter/nvim-treesitter`** | Parser de sintaxis avanzado y resaltado de código estructural. | Activo |

---

## 🛠️ 9. Comandos de Mantenimiento y Diagnóstico

Comandos integrados para verificar y actualizar el entorno:

- **`:Lazy`**: Abre la interfaz gráfica interactiva de Lazy para inspeccionar el estado de los plugins, tiempos de carga y dependencias.
- **`:Lazy sync`**: Sincroniza e instala cualquier plugin nuevo o actualiza los existentes respetando las especificaciones.
- **`:Lazy update`**: Comprueba y descarga las últimas versiones disponibles.
- **`:Lazy clean`**: Elimina plugins huérfanos que ya no estén presentes en la configuración.
- **`:checkhealth`**: Ejecuta la auditoría integral de salud de Neovim comprobando proveedores de portapapeles, Python, Node, parsers y ejecutables del sistema.

---

## ⚠️ Buenas Prácticas y Consejos Multiplataforma

1. **Tipografía estándar (Consolas / monospace):**
   - Configurada para máxima compatibilidad con fuentes limpias estándar como **Consolas** en Windows Terminal, sin requerir fuentes parchadas (*Nerd Fonts*) gracias a `icons_enabled = false` en `lualine`.
2. **Codificación de archivos:**
   - Mantén los archivos de configuración de Neovim (`.lua`) en formato **UTF-8** (sin BOM) con saltos de línea consistentes (`LF` o `CRLF`).
3. **Reproducibilidad:**
   - Si añades o eliminas plugins en [lua/plugins.lua](lua/plugins.lua), ejecuta `:Lazy sync` y añade al commit resultante tanto el archivo Lua como el [`lazy-lock.json`](lazy-lock.json) para mantener sincronizados todos tus equipos.

---

## 🗺️ Hoja de Ruta y Próximos Pasos

Consulta el documento **[`docs/future-improvements.md`](docs/future-improvements.md)** para revisar las mejoras planificadas a medio y largo plazo (configuración de Treesitter, sustitución de NERDTree por `oil.nvim`, integración de Lazygit, sinergia con notas y matriz de evaluación de seguridad).

