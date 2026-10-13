# ==============================================================================
# INSTALADOR Y APROVISIONAMIENTO DE LA CONFIGURACIÓN DE NEOVIM
# ==============================================================================
# Ejecuta este script en un equipo nuevo tras clonar el repositorio:
#   .\install.ps1               # Instalación interactiva guiada
#   .\install.ps1 -All          # Instalación desatendida completa
#   .\install.ps1 -InstallMissing
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$All,
    [switch]$InstallMissing,
    [switch]$NoTools,
    [switch]$SyncPlugins,
    [switch]$Force
)

$ErrorActionPreference = "Continue"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Instalación y Configuración del Entorno Neovim" -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 0. FUNCIONES AUXILIARES DE ENTORNO Y WINGET
# ------------------------------------------------------------------------------

function Update-SessionPath {
    try {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:PATH    = "$userPath;$machinePath"
    } catch {
        Write-Warning "No se pudo actualizar `$env:PATH dinámicamente: $_"
    }
}

function Test-CommandAvailable ([string]$CmdName) {
    if (Get-Command -Name $CmdName -CommandType Application, Alias -ErrorAction SilentlyContinue) {
        return $true
    }
    Update-SessionPath
    return [bool](Get-Command -Name $CmdName -CommandType Application, Alias -ErrorAction SilentlyContinue)
}

function Install-WingetPackage ([string]$PackageId, [string]$DisplayName, [string]$CheckCmd = $null) {
    if ($CheckCmd -and (Test-CommandAvailable $CheckCmd)) {
        Write-Host "  [OK] $DisplayName ya presente (comando '$CheckCmd')." -ForegroundColor Green
        return $true
    }

    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        Write-Warning "winget no está disponible en este equipo. No se puede instalar '$DisplayName'."
        return $false
    }

    Write-Host "  [>>] Instalando $DisplayName ($PackageId) con winget..." -ForegroundColor Cyan
    try {
        $proc = Start-Process -FilePath "winget" -ArgumentList "install", $PackageId, "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity" -NoNewWindow -Wait -PassThru
        Update-SessionPath
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
            Write-Host "  [OK] $DisplayName instalado/preparado correctamente." -ForegroundColor Green
            return $true
        } else {
            Write-Warning "winget finalizó con código $($proc.ExitCode) para '$DisplayName'."
            return $false
        }
    } catch {
        Write-Warning "Error al invocar winget para '$DisplayName': $_"
        return $false
    }
}

# ------------------------------------------------------------------------------
# 1. COMPROBACIÓN DE HERRAMIENTAS Y DEPENDENCIAS
# ------------------------------------------------------------------------------
Write-Host "1. Comprobando herramientas recomendadas..." -ForegroundColor DarkCyan

$dependencies = @(
    @{ Cmd = "nvim";  Name = "Neovim";                             Winget = "Neovim.Neovim";              Required = $true }
    @{ Cmd = "git";   Name = "Git (Gestor de repos y plugins)";    Winget = "Git.Git";                    Required = $true }
    @{ Cmd = "rg";    Name = "Ripgrep (Búsqueda Telescope)";       Winget = "BurntSushi.ripgrep.MSVC";    Required = $true }
    @{ Cmd = "fd";    Name = "fd (Buscador de archivos Telescope)";Winget = "sharkdp.fd";                 Required = $false }
    @{ Cmd = "clang"; Name = "LLVM / Clang (C para Treesitter)";   Winget = "LLVM.LLVM";                  Required = $false }
    @{ Cmd = "font";  Name = "JetBrainsMono Nerd Font";            Winget = "DEVCOM.JetBrainsMonoNerdFont"; Required = $false }
)

$missingReq = @()
$missingOpt = @()
foreach ($tool in $dependencies) {
    $exists = if ($tool.Cmd -eq "font") { $false } else { Test-CommandAvailable $tool.Cmd }
    if ($exists) {
        Write-Host "  [OK] $($tool.Name) disponible en el sistema." -ForegroundColor Green
    } else {
        if ($tool.Required) {
            Write-Host "  [--] $($tool.Name) NO encontrado (requerido)." -ForegroundColor Yellow
            $missingReq += $tool
        } else {
            Write-Host "  [○] $($tool.Name) no detectado (opcional)." -ForegroundColor DarkGray
            $missingOpt += $tool
        }
    }
}

# ------------------------------------------------------------------------------
# 2. INSTALACIÓN DE HERRAMIENTAS FALTANTES
# ------------------------------------------------------------------------------
if (-not $NoTools -and ($missingReq.Count -gt 0 -or $missingOpt.Count -gt 0)) {
    $shouldInstallReq = $false
    $shouldInstallOpt = $false

    $isInteractive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected

    if ($All -or $InstallMissing) {
        $shouldInstallReq = ($missingReq.Count -gt 0)
        $shouldInstallOpt = ($missingOpt.Count -gt 0)
    } elseif ($isInteractive) {
        if ($missingReq.Count -gt 0) {
            Write-Host ""
            $ans = Read-Host "¿Deseas instalar las herramientas requeridas faltantes con winget? ($($missingReq.Name -join ', ')) [S/n]"
            if ($ans -eq '' -or $ans -match '^[sSyY]') {
                $shouldInstallReq = $true
            }
        }
        if ($missingOpt.Count -gt 0) {
            Write-Host ""
            $ansOpt = Read-Host "¿Deseas instalar también utilidades opcionales (fuentes, compilador C)? ($($missingOpt.Name -join ', ')) [s/N]"
            if ($ansOpt -match '^[sSyY]') {
                $shouldInstallOpt = $true
            }
        }
    }

    if ($shouldInstallReq) {
        Write-Host "`n[*] Instalando dependencias requeridas con winget..." -ForegroundColor Cyan
        foreach ($t in $missingReq) {
            $chk = if ($t.Cmd -eq "font") { $null } else { $t.Cmd }
            Install-WingetPackage -PackageId $t.Winget -DisplayName $t.Name -CheckCmd $chk
        }
    }
    if ($shouldInstallOpt) {
        Write-Host "`n[*] Instalando utilidades opcionales con winget..." -ForegroundColor Cyan
        foreach ($t in $missingOpt) {
            $chk = if ($t.Cmd -eq "font") { $null } else { $t.Cmd }
            Install-WingetPackage -PackageId $t.Winget -DisplayName $t.Name -CheckCmd $chk
        }
    }
    Update-SessionPath
}

# ------------------------------------------------------------------------------
# 3. VINCULACIÓN NTFS (%LOCALAPPDATA%\nvim -> Repositorio)
# ------------------------------------------------------------------------------
Write-Host "`n2. Verificando vinculación de la configuración..." -ForegroundColor DarkCyan

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$targetDir = Join-Path $env:LOCALAPPDATA "nvim"

try {
    $item = Get-Item -LiteralPath $targetDir -ErrorAction SilentlyContinue
    $isJunction = $item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

    if ($isJunction -and -not $Force) {
        Write-Host "  [OK] Neovim en AppData ya está vinculado a dotfiles mediante Unión NTFS." -ForegroundColor Green
    } else {
        if (Test-Path -LiteralPath $targetDir) {
            $bak = "${targetDir}_bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -LiteralPath $targetDir -Destination $bak -Force
            Write-Host "  (!) Configuración previa respaldada en '$bak'." -ForegroundColor Yellow
        }
        cmd /c mklink /J "$targetDir" "$scriptDir" | Out-Null
        Write-Host "  [OK] Unión NTFS creada con éxito: '$targetDir' -> '$scriptDir'." -ForegroundColor Green
    }
} catch {
    Write-Warning "No se pudo vincular la configuración de Neovim: $_"
}

# ------------------------------------------------------------------------------
# 4. SINCRONIZACIÓN INICIAL DE PLUGINS (lazy.nvim)
# ------------------------------------------------------------------------------
if (Test-CommandAvailable "nvim") {
    Write-Host "`n3. Sincronizando plugins con lazy.nvim (headless)..." -ForegroundColor DarkCyan
    try {
        $nvimProc = Start-Process -FilePath "nvim" -ArgumentList "--headless", "+Lazy! sync", "+qa" -NoNewWindow -Wait -PassThru
        Write-Host "  [OK] Plugins sincronizados correctamente." -ForegroundColor Green
    } catch {
        Write-Warning "Aviso al sincronizar plugins: $_ (se descargarán la primera vez que abras nvim)."
    }
} else {
    Write-Host "`n  ○ Neovim no está disponible en PATH para sincronizar plugins." -ForegroundColor DarkGray
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  ¡Puesta a punto completada con éxito!" -ForegroundColor Green
Write-Host "  Ejecuta 'nvim' para empezar a trabajar." -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Green
