# ============================================================
# CONFIGURACIÓN GENERAL
# ============================================================
$ErrorActionPreference = "SilentlyContinue"
$urlPrincipal = "https://garciarussi.com"
$carpetaPrincipal = "C:\Instaladores"
# ============================================================
# ACTUALIZADOR
# ============================================================
$archivoActualizador = Join-Path $carpetaPrincipal "actualizador.ps1"
$archivoActualizadorTemp = Join-Path $carpetaPrincipal "actualizador_temp.ps1"
$urlActualizador = "$urlPrincipal/actualizador.ps1"
# ============================================================
# FONDO DE PANTALLA
# ============================================================
$archivoFondo = Join-Path $carpetaPrincipal "fondocomputadores.png"
$urlFondo = "$urlPrincipal/fondocomputadores.png"
# ============================================================
# ICONO DE SCRATCH
# ============================================================
$archivoScratchIcono = Join-Path $carpetaPrincipal "scratch.ico"
$urlScratchIcono = "$urlPrincipal/scratch.ico"
# ============================================================
# ESCRITORIO
# ============================================================
$escritorio = [Environment]::GetFolderPath("Desktop")
# ============================================================
# PROCESOS QUE SE DEBEN CERRAR
# ============================================================
$procesos = @(
    "chrome",
    "opera",
    "opera_gx",
    "launcher",
    "opera_autoupdate",
    "opera_crashreporter"
)
# ============================================================
# PROGRAMAS QUE SE DEBEN DESINSTALAR
# ============================================================
$programas = @(
    "*Google Chrome*",
    "*Opera*"
)
# ============================================================
# UBICACIONES DEL REGISTRO DE PROGRAMAS INSTALADOS
# ============================================================
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
# ============================================================
# POSIBLES UBICACIONES DEL DESINSTALADOR DE OPERA GX
# ============================================================
$operaGXLaunchers = @(
    "$env:LOCALAPPDATA\Programs\Opera GX\launcher.exe",
    "$env:ProgramFiles\Opera GX\launcher.exe",
    "${env:ProgramFiles(x86)}\Opera GX\launcher.exe"
)
# ============================================================
# CARPETAS RESIDUALES DE CHROME, OPERA Y OPERA GX
# ============================================================
$carpetasProgramas = @(
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
# ============================================================
# MICROSOFT EDGE
# ============================================================
$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
$edgeDefault = Join-Path $edgeUserData "Default"
$perfilesEdge = "Profile *"
$archivosEdgeDefault = @(
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
# ============================================================
# ACCESOS DIRECTOS PERMITIDOS
# ============================================================
$accesos = @(
    @{
        Nombre = "Microsoft Edge.lnk"
        Destino = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        Argumentos = ""
    },
    @{
        Nombre = "C$([char]0x00F3)digo Verde.lnk"
        Destino = "C:\Program Files (x86)\C$([char]0x00F3)digo Verde\C$([char]0x00F3)digo Verde.exe"
        Argumentos = ""
    },
    @{
        Nombre = "Tux Typing.lnk"
        Destino = "C:\Program Files (x86)\TuxType\TuxType.exe"
        Argumentos = ""
        Icono = "C:\Program Files (x86)\TuxType\data\tuxtype.ico"
    },
    @{
        Nombre = "RapidTyping 5.lnk"
        Destino = "C:\Program Files\RapidTyping 5\RapidTyping.exe"
        Argumentos = ""
    }
)
# ============================================================
# CREAR CARPETA PRINCIPAL
# ============================================================
try {
    if (-not (Test-Path $carpetaPrincipal)) {
        New-Item -Path $carpetaPrincipal -ItemType Directory -Force | Out-Null
    }
}
catch {
    Write-Host "No se pudo crear la carpeta principal, continuando..."
}
# ============================================================
# ACTUALIZACIÓN DEL PROPIO SCRIPT
# ============================================================
<#
# Este bloque está desactivado actualmente.
try {
    if (-not (Test-Path $archivoActualizadorTemp)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $urlActualizador -OutFile $archivoActualizadorTemp -UseBasicParsing -ErrorAction Stop
    }
    if (Test-Path $archivoActualizadorTemp) {
        $tamanoLocal = 0
        if (Test-Path $archivoActualizador) {
            $tamanoLocal = (Get-Item $archivoActualizador).Length
        }
        $tamanoRemoto = (Get-Item $archivoActualizadorTemp).Length
        if ($tamanoLocal -ne $tamanoRemoto) {
            Copy-Item -Path $archivoActualizadorTemp -Destination $archivoActualizador -Force -ErrorAction Stop
        }
        Remove-Item -Path $archivoActualizadorTemp -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Host "No se pudo actualizar el script, continuando..."
}
#>
# ============================================================
# DESCARGAR FONDO DE PANTALLA
# ============================================================
try {
    if (-not (Test-Path $archivoFondo)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $urlFondo -OutFile $archivoFondo -UseBasicParsing -ErrorAction Stop
    }
}
catch {
    Write-Host "No se pudo descargar el fondo de pantalla, continuando..."
}
# ============================================================
# APLICAR FONDO DE PANTALLA
# ============================================================
try {
    if (Test-Path $archivoFondo) {
        $fondoActual = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper").Wallpaper
        if ($fondoActual -ne $archivoFondo) {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value "10"
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "TileWallpaper" -Value "0"
            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@
            [Wallpaper]::SystemParametersInfo(20, 0, $archivoFondo, 3) | Out-Null
        }
    }
}
catch {
    Write-Host "No se pudo aplicar el fondo de pantalla, continuando..."
}
# ============================================================
# CERRAR CHROME Y OPERA
# ============================================================
try {
    foreach ($proceso in $procesos) {
        Stop-Process -Name $proceso -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Host "No se pudieron cerrar algunos procesos, continuando..."
}
Start-Sleep -Seconds 2
# ============================================================
# DESINSTALAR OPERA GX
# ============================================================
try {
    foreach ($launcher in $operaGXLaunchers) {
        if (Test-Path $launcher) {
            Start-Process -FilePath $launcher -ArgumentList "--uninstall", "--runimmediately", "--deleteuserprofile=1" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Host "No se pudo desinstalar Opera GX, continuando..."
}
# ============================================================
# DESINSTALAR CHROME Y OPERA
# ============================================================
try {
    foreach ($uninstallPath in $uninstallPaths) {
        $aplicaciones = Get-ItemProperty -Path $uninstallPath -ErrorAction SilentlyContinue
        foreach ($app in $aplicaciones) {
            if ($app.DisplayName -and ($programas | Where-Object { $app.DisplayName -like $_ }) -and $app.DisplayName -notlike "*Opera GX*") {
                if ($app.UninstallString) {
                    $uninstallString = $app.UninstallString.Trim()
                    if ($uninstallString.StartsWith('"')) {
                        $partes = $uninstallString -split '"'
                        $exe = $partes[1]
                        $argumentos = ""
                        if ($partes.Count -gt 2) {
                            $argumentos = $partes[2].Trim()
                        }
                    }
                    else {
                        $partes = $uninstallString -split "\s+", 2
                        $exe = $partes[0]
                        $argumentos = ""
                        if ($partes.Count -gt 1) {
                            $argumentos = $partes[1]
                        }
                    }
                    if (Test-Path $exe) {
                        Start-Process -FilePath $exe -ArgumentList $argumentos -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}
catch {
    Write-Host "No se pudieron desinstalar todos los programas, continuando..."
}
# ============================================================
# ELIMINAR CARPETAS RESIDUALES
# ============================================================
try {
    foreach ($carpeta in $carpetasProgramas) {
        if (Test-Path $carpeta) {
            Remove-Item -Path $carpeta -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Host "No se pudieron eliminar algunas carpetas residuales, continuando..."
}
# ============================================================
# DESCARGAR ICONO DE SCRATCH
# ============================================================
try {
    if (-not (Test-Path $archivoScratchIcono)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $urlScratchIcono -OutFile $archivoScratchIcono -UseBasicParsing -ErrorAction Stop
    }
}
catch {
    Write-Host "No se pudo descargar el icono de Scratch, continuando..."
}
# ============================================================
# PREPARAR LISTA DE ACCESOS PERMITIDOS
# ============================================================
$accesosPermitidos = @($accesos.Nombre)
$accesosPermitidos += "Scratch 3.lnk"
# ============================================================
# LIMPIAR ESCRITORIO
# ============================================================
try {
    Get-ChildItem -Path $escritorio -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.Name -notin $accesosPermitidos) {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
}
catch {
    Write-Host "No se pudo completar toda la limpieza del escritorio, continuando..."
}
# ============================================================
# CREAR ACCESOS DIRECTOS
# ============================================================
try {
    $WshShell = New-Object -ComObject WScript.Shell
    foreach ($acceso in $accesos) {
        $rutaAcceso = Join-Path $escritorio $acceso.Nombre
        if (-not (Test-Path $rutaAcceso)) {
            $shortcut = $WshShell.CreateShortcut($rutaAcceso)
            $shortcut.TargetPath = $acceso.Destino
            $shortcut.Arguments = $acceso.Argumentos
            $shortcut.WorkingDirectory = Split-Path $acceso.Destino
            if ($acceso.ContainsKey("Icono") -and (Test-Path $acceso.Icono)) {
                $shortcut.IconLocation = $acceso.Icono
            }
            $shortcut.Save()
        }
    }
}
catch {
    Write-Host "No se pudieron crear algunos accesos directos, continuando..."
}
# ============================================================
# DETECTAR SCRATCH 3
# ============================================================
try {
    $scratch = Get-StartApps | Where-Object { $_.Name -eq "Scratch 3" } | Select-Object -First 1
}
catch {
    $scratch = $null
}
# ============================================================
# CREAR ACCESO DIRECTO DE SCRATCH 3
# ============================================================
try {
    if ($scratch) {
        $rutaScratch = Join-Path $escritorio "Scratch 3.lnk"
        if (-not (Test-Path $rutaScratch)) {
            $shortcutScratch = $WshShell.CreateShortcut($rutaScratch)
            $shortcutScratch.TargetPath = "explorer.exe"
            $shortcutScratch.Arguments = "shell:AppsFolder\$($scratch.AppID)"
            if (Test-Path $archivoScratchIcono) {
                $shortcutScratch.IconLocation = $archivoScratchIcono
            }
            $shortcutScratch.Save()
        }
    }
}
catch {
    Write-Host "No se pudo crear el acceso directo de Scratch 3, continuando..."
}
# ============================================================
# LIMPIEZA DE MICROSOFT EDGE
# ============================================================
try {
    Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (Test-Path $edgeUserData) {
        Get-ChildItem -Path $edgeUserData -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like $perfilesEdge } |
            ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        if (Test-Path $edgeDefault) {
            foreach ($archivoEdge in $archivosEdgeDefault) {
                $rutaArchivoEdge = Join-Path $edgeDefault $archivoEdge
                if (Test-Path $rutaArchivoEdge) {
                    Remove-Item -Path $rutaArchivoEdge -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
catch {
    Write-Host "No se pudo completar toda la limpieza de Edge, continuando..."
}
# ============================================================
# FIN DEL PROCESO
# ============================================================
Write-Host "Proceso finalizado."
