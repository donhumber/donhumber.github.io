$ErrorActionPreference = "SilentlyContinue"
# Linea para poder activar los scripts
# Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
# ============================================================
# ACTUALIZADOR AUTOMÃTICO
# Se registra a sÃ­ mismo para ejecutarse al iniciar Windows
# ============================================================

$carpeta = "C:\Instaladores"
$archivoVersion = Join-Path $carpeta "version.txt"
$archivoScript = Join-Path $carpeta "Ejecucion.ps1"
$archivoTemporal = Join-Path $carpeta "Ejecucion_temp.ps1"

$baseUrl = "https://donhumber.github.io"
$urlVersion = "$baseUrl/version.txt"
$urlScript = "$baseUrl/ejecucion.ps1"

$nombreTarea = "Actualizador Institucional2"
$rutaActualizador = $PSCommandPath

# ------------------------------------------------------------
# CREAR CARPETA
# ------------------------------------------------------------

if (-not ( Test-Path $carpeta)) {
    Write-Host "Se debe crear la carpeta"
    New-Item -Path $carpeta -ItemType Directory -Force | Out-Null
}

# ------------------------------------------------------------
# REGISTRAR LA TAREA AUTOMÃTICAMENTE
# ------------------------------------------------------------

try {
    # Comprobar si tiene privilegios de administrador
    $principalActual = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )

    $esAdministrador = $principalActual.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($esAdministrador) {

        Write-Host "========================================="
        Write-Host "Inicio de registro de tarea programada"
        Write-Host "========================================="

        # Usuario con el que se está ejecutando PowerShell
        $usuarioPowerShell = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Host "PowerShell ejecutado como: $usuarioPowerShell"

        # Usuario que tiene actualmente iniciada la sesión de Windows
        $usuariopc = (Get-CimInstance Win32_ComputerSystem).UserName
        Write-Host "Usuario conectado en Windows: $usuariopc"

        if ([string]::IsNullOrWhiteSpace($usuariopc)) {
            throw "No se pudo determinar el usuario actualmente conectado en Windows."
        }

        # Comprobar si la tarea ya existe
        $tarea = Get-ScheduledTask `
            -TaskName $nombreTarea `
            -ErrorAction SilentlyContinue

        if (-not $tarea) {

            Write-Host "La tarea '$nombreTarea' no existe. Se procederá a registrarla."

            $argumentos = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$rutaActualizador`""

            $accion = New-ScheduledTaskAction `
                -Execute "powershell.exe" `
                -Argument $argumentos

            # Se activa cuando inicia sesión el usuario conectado
            $disparador = New-ScheduledTaskTrigger `
                -AtLogOn `
                -User $usuariopc `
                -RandomDelay (New-TimeSpan -Seconds 30)

            # Ejecutar como el usuario conectado con máximo nivel de privilegio
            $principalTarea = New-ScheduledTaskPrincipal `
                -UserId $usuariopc `
                -LogonType Interactive `
                -RunLevel Highest

            $configuracion = New-ScheduledTaskSettingsSet `
                -AllowStartIfOnBatteries `
                -DontStopIfGoingOnBatteries `
                -StartWhenAvailable

            Register-ScheduledTask `
                -TaskName $nombreTarea `
                -Action $accion `
                -Trigger $disparador `
                -Principal $principalTarea `
                -Settings $configuracion `
                -Force `
                -ErrorAction Stop | Out-Null

            Write-Host "Tarea registrada correctamente."

            # Verificar cómo quedó registrada realmente
            $tareaVerificada = Get-ScheduledTask `
                -TaskName $nombreTarea `
                -ErrorAction Stop

            Write-Host "-----------------------------------------"
            Write-Host "Verificación de la tarea:"
            Write-Host "Nombre      : $($tareaVerificada.TaskName)"
            Write-Host "Ruta        : $($tareaVerificada.TaskPath)"
            Write-Host "Usuario     : $($tareaVerificada.Principal.UserId)"
            Write-Host "LogonType   : $($tareaVerificada.Principal.LogonType)"
            Write-Host "RunLevel    : $($tareaVerificada.Principal.RunLevel)"
            Write-Host "Estado      : $($tareaVerificada.State)"
            Write-Host "-----------------------------------------"
        }
        else {

            Write-Host "La tarea '$nombreTarea' YA existe."

            Write-Host "-----------------------------------------"
            Write-Host "Configuración actual:"
            Write-Host "Nombre      : $($tarea.TaskName)"
            Write-Host "Ruta        : $($tarea.TaskPath)"
            Write-Host "Usuario     : $($tarea.Principal.UserId)"
            Write-Host "LogonType   : $($tarea.Principal.LogonType)"
            Write-Host "RunLevel    : $($tarea.Principal.RunLevel)"
            Write-Host "Estado      : $($tarea.State)"
            Write-Host "-----------------------------------------"
        }
    }
    else {
        Write-Host "Sin privilegios de administrador."
        Write-Host "Se omite el registro de la tarea."
    }
}
catch {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "ERROR AL REGISTRAR LA TAREA" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red

    Write-Host "Mensaje:"
    Write-Host $_.Exception.Message -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Tipo de excepción:"
    Write-Host $_.Exception.GetType().FullName

    Write-Host ""
    Write-Host "Código HRESULT:"
    Write-Host ("0x{0:X8}" -f $_.Exception.HResult)

    Write-Host ""
    Write-Host "Comando/ubicación:"
    Write-Host $_.InvocationInfo.PositionMessage

    Write-Host ""
    Write-Host "StackTrace:"
    Write-Host $_.ScriptStackTrace

    Write-Host "=========================================" -ForegroundColor Red
}


Write-Host "Verificando conexion a internet"
# ------------------------------------------------------------
# ESPERAR A QUE HAYA CONEXIÃ“N A INTERNET
# ------------------------------------------------------------

$internetDisponible = $false

for ($i = 0; $i -lt 12; $i++) {
    try {
        if ( Test-NetConnection "donhumber.github.io" -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue) {
            $internetDisponible = $true
            break
        }
    }
    catch {}

    Start-Sleep -Seconds 5
}


if ( $internetDisponible) {
    Write-Host "Verificando script remoto"
    # ------------------------------------------------------------
    # OBTENER VERSIÃ“N REMOTA
    # ------------------------------------------------------------

    try {
        $versionRemota = (Invoke-WebRequest `
            -Uri $urlVersion `
            -UseBasicParsing `
            -ErrorAction Stop).Content.Trim()
    }
    catch {
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($versionRemota)) {
        Write-Host "Errorr---------"
        exit 0
    }

    # ------------------------------------------------------------
    # OBTENER VERSIÃ“N LOCAL
    # ------------------------------------------------------------

    $versionLocal = ""
    if (Test-Path $archivoVersion) {
        try {
            $versionLocal = Get-Content -Path $archivoVersion -Raw -ErrorAction Stop 
            $versionLocal = $versionLocal.Trim()
        }
        catch {
            Write-Host "No se pudo leer el archivo de versiÃ³n: $($_.Exception.Message)"
            $versionLocal = ""
        }
    }

    # ------------------------------------------------------------
    # DETERMINAR SI HAY ACTUALIZACIÃ“N
    # ------------------------------------------------------------

    $actualizar = $false

    Write-Host "$archivoVersion - Version local $versionLocal version remota $versionRemota" 
    if (-not ( Test-Path $archivoVersion)) {
        Write-Host "Descargando 1"
        $actualizar = $true
    }
    elseif ($versionLocal -ne $versionRemota) {
        Write-Host "Descargando 2"
        $actualizar = $true
    }
    if ($versionLocal -ne $versionRemota) {
        Write-Host "Hay una version nueva: $versionRemota"
        $actualizar = $true
    }
    if ($actualizar) {
        # ------------------------------------------------------------
        # DESCARGAR NUEVO  Ejecucion.ps1
        # ------------------------------------------------------------
        Write-Host "Descargando archivos"
        try {
            Invoke-WebRequest `
                -Uri $urlScript `
                -OutFile $archivoTemporal `
                -UseBasicParsing `
                -ErrorAction Stop
        }
        catch {
            Write-Host "Error al descargar: $($_.Exception.Message)"
            Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue
            Write-Host "Error1"
        }

        # ------------------------------------------------------------
        # VALIDAR DESCARGA
        # ------------------------------------------------------------

        if (-not ( Test-Path $archivoTemporal)) {
            exit 0
        }

        try {
            $tamano = (Get-Item $archivoTemporal -ErrorAction Stop).Length
        }
        catch {
            Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue
            exit 0
        }

        if ($tamano -le 0) {
            Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue
            exit 0
        }

        # ------------------------------------------------------------
        # REEMPLAZAR  Ejecucion.ps1
        # ------------------------------------------------------------

        try {
            Move-Item `
                -Path $archivoTemporal `
                -Destination $archivoScript `
                -Force `
                -ErrorAction Stop
        }
        catch {
            Remove-Item $archivoTemporal -Force -ErrorAction SilentlyContinue
            exit 0
        }

        # ------------------------------------------------------------
        # ACTUALIZAR VERSION LOCAL
        # ------------------------------------------------------------

        try {
            Set-Content `
                -Path $archivoVersion `
                -Value $versionRemota `
                -Encoding UTF8 `
                -Force `
                -ErrorAction Stop
        }
        catch {
            exit 0
        }
    }

}


# ------------------------------------------------------------
# EJECUTAR  Ejecucion.ps1
# ------------------------------------------------------------

Write-Host "Ejecutando rutina de limpieza"
try {
    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$archivoScript`"" `
        -WindowStyle Hidden `
        -Wait
}
catch {
    exit 0
}

exit 0

