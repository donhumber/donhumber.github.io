$ErrorActionPreference = "SilentlyContinue"

$urlprincial = "https://" + "garciarussi.com/"
$carpetaprincipal   = "C:\Instaladores\"

$archivoLocal = $carpetaprincipal + "actualizador.ps1"
$archivoTemporal = $carpetaprincipal + "actualizador_temp.ps1"
$url = $urlprincial + "actualizador.ps1"

<# 
Write-Host "====================================="
Write-Host "     actualizando archivo original"
Write-Host "====================================="

try {
    # Descargar la versión de Internet a un archivo temporal
    Invoke-WebRequest -Uri $url -OutFile $archivoTemporal -UseBasicParsing

    # Obtener tamaños
    $tamanoLocal = (Get-Item $archivoLocal).Length
    $tamanoNuevo = (Get-Item $archivoTemporal).Length

    Write-Host "Tamaño local:    $tamanoLocal bytes"
    Write-Host "Tamaño Internet: $tamanoNuevo bytes"

    # Comparar tamaños
    if ($tamanoLocal -ne $tamanoNuevo) {

        Write-Host "Los archivos tienen diferente tamaño."
        Write-Host "Reemplazando archivo local..."

        Copy-Item -Path $archivoTemporal -Destination $archivoLocal -Force

        Write-Host "Archivo actualizado correctamente."
    }
    else {
        Write-Host "Los archivos tienen el mismo tamaño."
        Write-Host "No es necesario actualizar."
    }

    # Eliminar archivo temporal
    Remove-Item $archivoTemporal -Force
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    # Intentar eliminar el temporal si quedó creado
    if (Test-Path $archivoTemporal) {
        Remove-Item $archivoTemporal -Force
    }
}
Write-Host "====================================="
Write-Host "     Limpiando computador"
Write-Host "====================================="
#>
# ============================================================
# CONFIGURACIÓN
# ============================================================


$archivo = Join-Path $carpetaprincipal "fondocomputadores.png"

# Se divide la URL para evitar problemas al copiar el script
$url = $urlprincial + "fondocomputadores.png"

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
if ((Test-Path $archivo)) {

    # ============================================================
    # COMPROBAR SI EL FONDO YA ES EL CORRECTO
    # ============================================================

    $fondoActual = (Get-ItemProperty `
        -Path "HKCU:\Control Panel\Desktop" `
        -Name "Wallpaper" `
        -ErrorAction SilentlyContinue
    ).Wallpaper

    if ($fondoActual -ne $archivo) {

        # ========================================================
        # CONFIGURAR EL FONDO DE WINDOWS
        # ========================================================

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

        # ========================================================
        # APLICAR EL FONDO DE PANTALLA
        # ========================================================

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

    }
}

Write-Host "     Desinstalando programas no deseados"
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
# CERRAR PROCESOS
# ============================================================

$procesos = @(
    "chrome",
    "opera",
    "opera_gx",
    "launcher",
    "opera_autoupdate",
    "opera_crashreporter"
)

foreach ($proceso in $procesos) {
    Get-Process -Name $proceso -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}


# ============================================================
# DESINSTALAR OPERA GX
# ============================================================

$operaGXLaunchers = @(
    "$env:LOCALAPPDATA\Programs\Opera GX\launcher.exe",
    "$env:ProgramFiles\Opera GX\launcher.exe",
    "${env:ProgramFiles(x86)}\Opera GX\launcher.exe"
)

foreach ($launcher in $operaGXLaunchers) {

    if (Test-Path $launcher) {

        Write-Host "Desinstalando Opera GX..."

        Start-Process `
            -FilePath $launcher `
            -ArgumentList "--uninstall", "--runimmediately", "--deleteuserprofile=1" `
            -Wait `
            -WindowStyle Hidden `
            -ErrorAction SilentlyContinue
    }
}


# ============================================================
# DESINSTALAR CHROME Y OPERA NORMAL
# ============================================================

$programas = @(
    "*Google Chrome*",
    "*Opera*"
)

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $uninstallPaths) {

    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue

    foreach ($app in $apps) {

        if ($app.DisplayName -and
            ($programas | Where-Object {
                $app.DisplayName -like $_ -and
                $app.DisplayName -notlike "*Opera GX*"
            })) {

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
                    -ArgumentList $args `
                    -Wait `
                    -WindowStyle Hidden `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}


# ============================================================
# ELIMINAR CARPETAS RESIDUALES
# ============================================================

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


# ============================================
# CONFIGURACIÓN DE ACCESOS DIRECTOS
# ============================================

$escritorio = [Environment]::GetFolderPath("Desktop")

$accesos = @(
    @{
        Nombre = "Microsoft Edge.lnk"
        Destino = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        Argumentos = ""
    },
    @{
        Nombre = "Código Verde"
        Destino = "C:\Program Files (x86)\Código Verde\Código Verde.exe"
        Argumentos = ""
    }
    @{
        Nombre = "TuxTyping"
        Destino = "C:\Program Files (x86)\TuxType\TuxType.exe.exe"
        Argumentos = ""
    }
    @{
        Nombre = "RapidTyping 5"
        Destino = "C:\Program Files (x86)\RapidTyping 5\RapidTyping.exe.exe"
        Argumentos = ""
    }
)


# ============================================
# ELIMINAR ACCESOS DIRECTOS NO AUTORIZADOS
# ============================================

$accesosPermitidos = $accesos.Nombre

#Get-ChildItem -Path $escritorio -Filter "*.lnk" -File -ErrorAction SilentlyContinue |
#    ForEach-Object {
#
#        if ($_.Name -notin $accesosPermitidos) {
#
#            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
#
#        }
#    }


# ============================================
# CREAR ACCESOS DIRECTOS QUE NO EXISTAN
# ============================================

$WshShell = New-Object -ComObject WScript.Shell

foreach ($acceso in $accesos) {

    $rutaAcceso = Join-Path $escritorio $acceso.Nombre

    if (-not (Test-Path $rutaAcceso)) {

        $shortcut = $WshShell.CreateShortcut($rutaAcceso)

        $shortcut.TargetPath = $acceso.Destino
        $shortcut.Arguments = $acceso.Argumentos

        if (Test-Path $acceso.Destino -PathType Leaf) {
            $shortcut.WorkingDirectory = Split-Path $acceso.Destino
        }

        $shortcut.Save()
    }
}

$escritorio = [Environment]::GetFolderPath("Desktop")

$scratch = Get-StartApps | Where-Object { $_.Name -eq "Scratch 3" } | Select-Object -First 1

if ($scratch) {

    $rutaAcceso = Join-Path $escritorio "Scratch 3.lnk"

    if (-not (Test-Path $rutaAcceso)) {

        $WshShell = New-Object -ComObject WScript.Shell
        $acceso = $WshShell.CreateShortcut($rutaAcceso)

        $acceso.TargetPath = "explorer.exe"
        $acceso.IconLocation = "C:\Instaladores\Scratch.ico"
        $acceso.Arguments = "shell:AppsFolder\$($scratch.AppID)"
        $acceso.Save()
    }
}

# ============================================================
# LIMPIAR MICROSOFT EDGE
# ============================================================

Write-Host "     Limpiando perfiles y datos de Microsoft Edge..."

$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

# ------------------------------------------------------------
# Cerrar Microsoft Edge
# ------------------------------------------------------------

Get-Process -Name "msedge" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Pequeña espera para asegurar que los archivos queden libres
Start-Sleep -Seconds 2

# ------------------------------------------------------------
# Comprobar que existe la instalación de datos
# ------------------------------------------------------------

if (Test-Path $edgeUserData) {

    # --------------------------------------------------------
    # Eliminar perfiles secundarios
    # Conservamos únicamente "Default"
    # --------------------------------------------------------

    Get-ChildItem $edgeUserData -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "Profile *"
        } |
        ForEach-Object {

            Write-Host "Eliminando perfil de Edge: $($_.Name)"

            Remove-Item $_.FullName `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        }

    # --------------------------------------------------------
    # Perfil principal
    # --------------------------------------------------------

    $edgeDefault = Join-Path $edgeUserData "Default"

    if (Test-Path $edgeDefault) {

        # Archivos relacionados con historial,
        # credenciales, cookies y datos personales
        $archivosEdge = @(
            "History",
            "History-journal",
            "Visited Links",

            "Login Data",
            "Login Data For Account",
            "Login Data-journal",

            "Web Data",
            "Web Data-journal",

            "Cookies",
            "Cookies-journal"
        )

        foreach ($archivo in $archivosEdge) {

            $ruta = Join-Path $edgeDefault $archivo

            if (Test-Path $ruta) {

                Write-Host "Eliminando: $archivo"

                Remove-Item $ruta `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "     Limpieza de Microsoft Edge completada."
