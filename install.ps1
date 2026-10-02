# ==============================================================================
# INSTALADOR Y APROVISIONAMIENTO DE LA CONFIGURACION DE NEOVIM
# ==============================================================================
# Ejecuta este script en un equipo nuevo tras clonar el repositorio:
#   .\install.ps1
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$InstallMissing,
    [switch]$SyncPlugins
)

$ErrorActionPreference = "Stop"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Instalacion y Configuracion del Entorno Neovim" -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Cyan

# 1. Comprobacion y verificacion de Neovim
Write-Host "[*] Comprobando instalacion de Neovim..." -ForegroundColor Cyan
$nvimCmd = Get-Command -Name "nvim" -CommandType Application -ErrorAction SilentlyContinue

if ($nvimCmd) {
    $rawVersion = & $nvimCmd.Source --version | Select-Object -First 1
    Write-Host "[+] Neovim detectado: $rawVersion" -ForegroundColor Green
    Write-Host "    Ruta: $($nvimCmd.Source)" -ForegroundColor DarkGray
}
else {
    Write-Host "[-] Neovim NO esta instalado o no se encuentra en el PATH." -ForegroundColor Red
    if ($InstallMissing) {
        Write-Host "[*] Instalando Neovim mediante winget..." -ForegroundColor Cyan
        winget install Neovim.Neovim --accept-source-agreements --accept-package-agreements
    }
    else {
        Write-Host "    Instalalo con: winget install Neovim.Neovim" -ForegroundColor Yellow
    }
}

# 2. Comprobacion de herramientas CLI recomendadas
Write-Host "`n--- Comprobando herramientas recomendadas del sistema ---" -ForegroundColor DarkGray

$cliTools = @(
    @{ Cmd = "git"; Name = "Git (Gestor de versiones y plugins)"; Winget = "Git.Git"; Required = $true }
    @{ Cmd = "rg";  Name = "Ripgrep (Busqueda ultrarrapida Telescope)"; Winget = "BurntSushi.ripgrep.MSVC"; Required = $true }
    @{ Cmd = "fd";  Name = "fd (Buscador rapido de ficheros)"; Winget = "sharkdp.fd"; Required = $false }
    @{ Cmd = "gcc"; Name = "GCC / Compilador C (Parsers de Treesitter)"; Winget = "LLVM.LLVM"; Required = $false }
)

$missingTools = @()
foreach ($tool in $cliTools) {
    $cmd = Get-Command -Name $tool.Cmd -CommandType Application -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[+] $($tool.Name) encontrado en: $($cmd.Source)" -ForegroundColor Green
    }
    else {
        if ($tool.Required) {
            Write-Host "[-] $($tool.Name) NO encontrado (requerido)" -ForegroundColor Red
        }
        else {
            Write-Host "[o] $($tool.Name) no encontrado en PATH (opcional)" -ForegroundColor DarkGray
        }
        $missingTools += $tool.Winget
    }
}

if ($missingTools.Count -gt 0 -and -not $InstallMissing) {
    Write-Host "`nTip: Puedes instalar las herramientas faltantes con winget:" -ForegroundColor DarkCyan
    Write-Host "  winget install $($missingTools -join ' ')`n" -ForegroundColor DarkYellow
}
elseif ($missingTools.Count -gt 0 -and $InstallMissing) {
    Write-Host "`n[*] Instalando dependencias faltantes..." -ForegroundColor Cyan
    winget install $($missingTools -join ' ') --accept-source-agreements --accept-package-agreements
}

# 3. Verificacion de ubicacion del repositorio
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$targetDir = Join-Path $env:LOCALAPPDATA "nvim"

Write-Host "`n[*] Verificando ubicacion de la configuracion..." -ForegroundColor Cyan
if ((Resolve-Path -LiteralPath $scriptDir).Path -ieq (Resolve-Path -LiteralPath $targetDir -ErrorAction SilentlyContinue).Path) {
    Write-Host "[+] La configuracion esta ubicada correctamente en: $targetDir" -ForegroundColor Green
}
else {
    Write-Host "[!] Nota: Este repositorio se encuentra en: $scriptDir" -ForegroundColor Yellow
    Write-Host "    Para que Neovim lo cargue en Windows, asegurate de que este en: $targetDir" -ForegroundColor DarkGray
    Write-Host "    (Puedes crear un enlace simbolico o mover la carpeta si es necesario)." -ForegroundColor DarkGray
}

# 4. Sincronizacion inicial de plugins
if ($SyncPlugins -or $nvimCmd) {
    Write-Host "`n[*] Sincronizando plugins de Neovim con lazy.nvim (headless)..." -ForegroundColor Cyan
    try {
        & nvim --headless "+Lazy! sync" +qa
        Write-Host "[+] Plugins sincronizados correctamente." -ForegroundColor Green
    }
    catch {
        Write-Warning "No se pudo sincronizar automaticamente los plugins: $_"
        Write-Host "    Se sincronizaran la primera vez que abras Neovim manualmente." -ForegroundColor DarkGray
    }
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  Puesta a punto completada! Ejecuta 'nvim' para empezar." -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
