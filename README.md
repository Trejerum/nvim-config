# 🚀 Neovim Configuration

Configuración personalizada de **Neovim** escrita en **Lua**, modular y gestionada con [lazy.nvim](https://github.com/folke/lazy.nvim). Diseñada para ofrecer un entorno de desarrollo ágil, ligero y reproducible entre diferentes sistemas operativos (Windows, Linux y macOS).

---

## 📋 Requisitos Previos

Antes de clonar e iniciar Neovim, asegúrate de contar con las siguientes herramientas instaladas en tu sistema:

| Herramienta | Descripción | Instalación rápida |
| :--- | :--- | :--- |
| **Neovim** (>= 0.9.0) | Editor principal | [Descargas oficiales](https://github.com/neovim/neovim/releases) |
| **Git** | Clonado del repositorio y gestor de plugins | `git --version` |
| **Ripgrep (`rg`)** | Búsqueda rápida de texto con Telescope | `winget install BurntSushi.ripgrep.MSVC` / `brew install ripgrep` / `sudo apt install ripgrep` |
| **fd** *(opcional)* | Búsqueda optimizada de archivos | `winget install sharkdp.fd` / `brew install fd` / `sudo apt install fd-find` |
| **Nerd Font** | Tipografía con iconos para `lualine` | [Nerd Fonts](https://www.nerdfonts.com/) (ej. *JetBrainsMono Nerd Font*) |
| **Compilador C** *(opcional)* | GCC, Clang o MSVC para parsers de Treesitter | `winget install LLVM.LLVM` / `sudo apt install build-essential` |

---

## 📦 Instalación

El archivo [`init.lua`](init.lua) incluye bootstrapping automático: la primera vez que inicies Neovim, descargará `lazy.nvim` de forma autónoma e instalará los plugins bloqueados en [`lazy-lock.json`](lazy-lock.json).

### 🪟 Windows (PowerShell)

```powershell
# 1. (Opcional) Haz una copia de seguridad si ya tienes una configuración previa
if (Test-Path "$env:LOCALAPPDATA\nvim") {
    Rename-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim.backup"
}

# 2. Clona el repositorio en AppData\Local\nvim
git clone https://github.com/Trejerum/nvim-config.git $env:LOCALAPPDATA\nvim

# 3. Abre Neovim para que lazy.nvim instale los plugins
nvim
```

### 🐧 Linux / 🍎 macOS (Bash / Zsh)

```bash
# 1. (Opcional) Copia de seguridad si ya existe configuración previa
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"

# 2. Clona el repositorio en ~/.config/nvim
git clone https://github.com/Trejerum/nvim-config.git ~/.config/nvim

# 3. Abre Neovim
nvim
```

---

## 📂 Estructura del Proyecto

```text
nvim/
├── init.lua                # Punto de entrada: arranque de lazy.nvim y carga de módulos
├── lazy-lock.json          # Versiones exactas y bloqueadas de los plugins instalados
├── README.md               # Documentación del proyecto
└── lua/
    ├── globals.lua         # Variables globales (ej. vim.g.autoformat)
    ├── opts.lua            # Opciones de editor (números de línea, indentación, tabs)
    ├── mappings.lua        # Atajos de teclado personalizados
    ├── plugins.lua         # Lista y especificación de plugins gestionados por Lazy
    └── config/             # Configuraciones específicas por plugin
        ├── debugprint.lua  # Opciones y comandos para debugprint.nvim
        ├── gitsigns.lua    # Configuración de indicadores Git en el gutter
        ├── lualine.lua     # Aspecto y secciones de la barra de estado
        └── nvim_hop.lua    # Configuración de saltos rápidos con Hop
```

---

## ⌨️ Atajos de Teclado (Keymaps)

La tecla **Leader** está configurada como `<Space>` (Espacio).

### 🔍 Telescope (Buscador Difuso)

| Atajo | Comando | Descripción |
| :--- | :--- | :--- |
| `<Leader>tf` | `:Telescope find_files` | Buscar archivos en el proyecto |
| `<Leader>tg` | `:Telescope live_grep` | Búsqueda de texto en vivo (requiere `ripgrep`) |
| `<Leader>tb` | `:Telescope buffers` | Listar y cambiar de buffers abiertos |
| `<Leader>th` | `:Telescope help_tags` | Buscar en la ayuda de Neovim |
| `<Leader>ts` | `:Telescope grep_string` | Buscar ocurrencias de la palabra bajo el cursor |
| `<Leader>tr` | `:Telescope resume` | Reanudar la última búsqueda |

### 🗂️ Explorador de Archivos (NERDTree)

| Atajo | Comando | Descripción |
| :--- | :--- | :--- |
| `<Leader><TAB>` | `:NERDTreeToggle` | Abrir / cerrar el árbol lateral |
| `<Leader>r` | `:NERDTreeFind` | Localizar el archivo actual en el árbol |

### 🪟 Gestión de Ventanas y Splits

| Atajo | Modo | Descripción |
| :--- | :---: | :--- |
| `<Ctrl-h>` | Normal | Mover foco al split izquierdo |
| `<Ctrl-j>` | Normal | Mover foco al split inferior |
| `<Ctrl-k>` | Normal | Mover foco al split superior |
| `<Ctrl-l>` | Normal | Mover foco al split derecho |
| `<Ctrl-Left>` | Normal | Reducir ancho del split (`-10`) |
| `<Ctrl-Right>` | Normal | Aumentar ancho del split (`+10`) |
| `<Ctrl-Up>` | Normal | Reducir alto del split (`-10`) |
| `<Ctrl-Down>` | Normal | Aumentar alto del split (`+10`) |

### 🐇 Movimiento Rápido (Hop)

| Atajo | Modos | Descripción |
| :--- | :---: | :--- |
| `f` | Normal, Visual, Operador | Salto rápido bidireccional de 2 caracteres en pantalla |

### ✏️ Edición y Registros

| Atajo | Modo | Descripción |
| :--- | :---: | :--- |
| `<Leader>v` | Normal | Reseleccionar el último bloque de texto pegado |
| `p` | Visual | Pegar sobre selección sin sobreescribir el registro por defecto |
| `<Alt-j>` | Visual | Mover línea/bloque seleccionado hacia abajo |

---

## 🔌 Plugins Instalados

| Plugin | Propósito |
| :--- | :--- |
| [folke/lazy.nvim](https://github.com/folke/lazy.nvim) | Gestor de plugins moderno y rápido |
| [scrooloose/nerdtree](https://github.com/scrooloose/nerdtree) | Árbol de archivos y navegación |
| [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Buscador difuso modular y potente |
| [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Utilidades Lua (dependencia de Telescope) |
| [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Barra de estado rápida y personalizable |
| [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive) | Integración con Git dentro de Neovim |
| [folke/which-key.nvim](https://github.com/folke/which-key.nvim) | Popup visual que sugiere combinaciones de teclas |
| [tpope/vim-surround](https://github.com/tpope/vim-surround) | Modificación rápida de comillas, paréntesis y tags |
| [numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim) | Comentarios de código rápidos (`gcc`, `gc`) |
| [smoka7/hop.nvim](https://github.com/smoka7/hop.nvim) | Navegación precisa estilo EasyMotion |
| [sbdchd/neoformat](https://github.com/sbdchd/neoformat) | Formateador de código universal |
| [folke/neoconf.nvim](https://github.com/folke/neoconf.nvim) | Configuración de proyecto local |
| [andrewferrier/debugprint.nvim](https://github.com/andrewferrier/debugprint.nvim) | Inserción rápida de sentencias de debug print |

---

## 🛠️ Comandos Útiles

- `:Lazy` — Abrir la interfaz de gestión de plugins.
- `:Lazy sync` — Sincronizar e instalar/actualizar plugins según la configuración.
- `:Lazy check` — Comprobar si hay actualizaciones disponibles.
- `:checkhealth` — Diagnóstico general del estado de Neovim y dependencias del sistema.
