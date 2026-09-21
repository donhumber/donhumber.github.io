$ErrorActionPreference = "SilentlyContinue"

Write-Host "====================================="
Write-Host "     Limpiando computador"
Write-Host "====================================="


# ============================================================
# CONFIGURACIÓN
# ============================================================

$carpeta = "C:\Instaladores"
$archivo = Join-Path $carpeta "fondocomputadores.png"

# Se divide la URL para evitar problemas al copiar el script
$url = "https://" + "garciarussi.com/fondocomputadores.png"

# ============================================================
# CREAR CARPETA SI NO EXISTE
# ============================================================

if (-not (Test-Path $carpeta)) {
    New-Item -Path $carpeta -ItemType Directory -Force | Out-Null
}

# ============================================================
# DESCARGAR LA IMAGEN SI NO EXISTE
# ============================================================

if (-not (Test-Path $archivo)) {

    try {

        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.SecurityProtocolType]::Tls12

        Invoke-WebRequest `
            -Uri $url `
            -OutFile $archivo `
            -UseBasicParsing `
            -ErrorAction SilentlyContinue

    }
    catch {
        exit 0
    }
}

# ============================================================
# COMPROBAR QUE LA IMAGEN EXISTE ANTES DE CONTINUAR
# ============================================================

if (-not (Test-Path $archivo)) {
    exit 0
}

# ============================================================
# CONFIGURAR EL FONDO DE WINDOWS
# ============================================================

Set-ItemProperty `
    -Path "HKCU:\Control Panel\Desktop" `
    -Name "WallpaperStyle" `
    -Value "10" `
    -ErrorAction SilentlyContinue

Set-ItemProperty `
    -Path "HKCU:\Control Panel\Desktop" `
    -Name "TileWallpaper" `
    -Value "0" `
    -ErrorAction SilentlyContinue

# ============================================================
# APLICAR EL FONDO DE PANTALLA
# ============================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@

# SPI_SETDESKWALLPAPER = 20
# SPIF_UPDATEINIFILE = 1
# SPIF_SENDCHANGE    = 2

[Wallpaper]::SystemParametersInfo(
    20,
    0,
    $archivo,
    3
) | Out-Null


Write-Host "     Desinstalando programas no deseados"
$ErrorActionPreference = 'SilentlyContinue'

# Programas que se desean desinstalar
$programas = @(
    "*Google Chrome*",
    "*Opera*",
    "*Opera GX*"
)

# Cerrar procesos relacionados
$procesos = @(
    "chrome",
    "opera",
    "opera_gx",
    "launcher"
)

foreach ($proceso in $procesos) {
    Get-Process -Name $proceso -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

# Ubicaciones del registro donde pueden estar registrados los programas
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Buscar y desinstalar
foreach ($path in $uninstallPaths) {

    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue

    foreach ($app in $apps) {

        if ($app.DisplayName -and
            ($programas | Where-Object { $app.DisplayName -like $_ })) {

            if ($app.UninstallString) {

                $uninstall = $app.UninstallString.Trim()

                if ($uninstall -match '^"([^"]+)"\s*(.*)$') {
                    $exe = $matches[1]
                    $args = $matches[2]
                }
                else {
                    $parts = $uninstall -split '\s+', 2
                    $exe = $parts[0]
                    $args = if ($parts.Count -gt 1) {
                        $parts[1]
                    }
                    else {
                        ""
                    }
                }

                Start-Process `
                    -FilePath $exe `
                    -ArgumentList "$args --force-uninstall" `
                    -Wait `
                    -WindowStyle Hidden `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}

# Eliminar carpetas residuales
$carpetas = @(
    "$env:ProgramFiles\Google\Chrome",
    "${env:ProgramFiles(x86)}\Google\Chrome",
    "$env:LOCALAPPDATA\Google\Chrome",
    "$env:PROGRAMDATA\Google\Chrome",

    "$env:ProgramFiles\Opera",
    "${env:ProgramFiles(x86)}\Opera",
    "$env:LOCALAPPDATA\Programs\Opera",
    "$env:APPDATA\Opera Software",
    "$env:LOCALAPPDATA\Opera Software",

    "$env:ProgramFiles\Opera GX",
    "${env:ProgramFiles(x86)}\Opera GX",
    "$env:LOCALAPPDATA\Programs\Opera GX",
    "$env:APPDATA\Opera Software\Opera GX Stable",
    "$env:LOCALAPPDATA\Opera Software\Opera GX Stable"
)

foreach ($carpeta in $carpetas) {

    if (Test-Path $carpeta) {
        Remove-Item $carpeta `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}