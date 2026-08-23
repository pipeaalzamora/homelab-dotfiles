<#
.SYNOPSIS
Script de instalacion completa para el homelab en Windows (localhost).

.DESCRIPTION
Verifica requisitos, configura entorno local, genera secreto .env,
crea directorios, copia configuraciones, despliega contenedores y
genera un README post-instalacion.
#>

$ErrorActionPreference = "Stop"

# Variables Globales
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$HOMELAB_ROOT = Join-Path $env:USERPROFILE "homelab"
$START_TIME = Get-Date

function Write-Step {
    param([string]$Text)
    Write-Host "`n[>] $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Text)
    Write-Host "[WARN] $Text" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host "[ERROR] $Text" -ForegroundColor Red
}

function Get-RandomHex { 
    param([int]$bytes)
    $rb = New-Object byte[] $bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rb)
    ($rb | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-RandomB64 { 
    param([int]$bytes)
    $rb = New-Object byte[] $bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rb)
    [Convert]::ToBase64String($rb) -replace '[/+=]',''
}

try {
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "*** INICIANDO INSTALACION DEL HOMELAB ***" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta

    # ==========================================
    # Fase 1: Check Prerequisites
    # ==========================================
    Write-Step "Fase 1: Verificando requisitos previos..."

    # Docker
    try {
        $dockerVer = docker --version 2>&1
        Write-Success "Docker encontrado: $dockerVer"
    } catch {
        Write-ErrorMsg "Docker no encontrado. Instala Docker Desktop: https://www.docker.com/products/docker-desktop/"
        exit 1
    }

    # Docker Compose
    try {
        $composeVer = docker compose version 2>&1
        Write-Success "Docker Compose encontrado: $composeVer"
    } catch {
        Write-ErrorMsg "Docker Compose v2 no encontrado."
        exit 1
    }

    # Git
    try {
        $gitVer = git --version 2>&1
        Write-Success "Git encontrado: $gitVer"
    } catch {
        Write-ErrorMsg "Git no encontrado. Instala Git: https://git-scm.com/download/win"
        exit 1
    }

    # Docker Daemon
    try {
        $null = docker info 2>&1
        Write-Success "Docker Daemon en ejecucion."
    } catch {
        Write-ErrorMsg "Docker Daemon no esta corriendo. Inicia Docker Desktop."
        exit 1
    }

    # RAM (Advertencia si < 4GB)
    $ram = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    if ($ramGB -lt 4) {
        Write-WarningMsg "RAM detectada: $ramGB GB - menor a 4GB recomendado."
    } else {
        Write-Success "RAM suficiente: $ramGB GB"
    }

    # Disk Free Space (Advertencia si < 20GB en C:)
    $disk = Get-PSDrive C
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    if ($freeGB -lt 20) {
        Write-WarningMsg "Espacio libre en C: $freeGB GB - menor a 20GB recomendado."
    } else {
        Write-Success "Espacio en disco suficiente: $freeGB GB"
    }

    # ==========================================
    # Fase 2: Configurar Acceso Local (localhost)
    # ==========================================
    Write-Step "Fase 2: Configurando acceso local..."
    $HOST_IP = "localhost"
    Write-Success "Host configurado: $HOST_IP (127.0.0.1)"

    # ==========================================
    # Fase 3: Generate env/.env
    # ==========================================
    Write-Step "Fase 3: Generando env/.env con secretos seguros..."

    $ENV_DIR = Join-Path $SCRIPT_DIR "env"
    if (!(Test-Path $ENV_DIR)) { New-Item -ItemType Directory -Path $ENV_DIR -Force | Out-Null }
    $ENV_FILE = Join-Path $ENV_DIR ".env"

    $HOMELAB_ROOT_LINUX = $HOMELAB_ROOT.Replace('\', '/')

    # Generar secretos necesarios
    $INFISICAL_DB_PASS = Get-RandomB64 32
    $INFISICAL_KEY = Get-RandomHex 16
    $INFISICAL_SECRET = Get-RandomB64 32
    $RESTIC_PASS = Get-RandomB64 32
    $QBIT_PASS = (Get-RandomB64 18).Substring(0, 16)
    $APPFLOWY_PASS_VAL = (Get-RandomB64 18).Substring(0, 16)

    $templatePath = Join-Path $SCRIPT_DIR "configs\env.template"
    $envTemplate = Get-Content -Path $templatePath -Raw -Encoding UTF8

    $envText = $envTemplate
    $envText = $envText.Replace('__HOMELAB_ROOT_LINUX__', $HOMELAB_ROOT_LINUX)
    $envText = $envText.Replace('__HOST_IP__', $HOST_IP)
    $envText = $envText.Replace('__INFISICAL_DB_PASS__', $INFISICAL_DB_PASS)
    $envText = $envText.Replace('__INFISICAL_KEY__', $INFISICAL_KEY)
    $envText = $envText.Replace('__INFISICAL_SECRET__', $INFISICAL_SECRET)
    $envText = $envText.Replace('__RESTIC_PASS__', $RESTIC_PASS)
    $envText = $envText.Replace('__QBIT_PASS__', $QBIT_PASS)

    Set-Content -Path $ENV_FILE -Value $envText -Encoding UTF8
    Write-Success "Archivo .env generado correctamente."

    # ==========================================
    # Fase 4: Create Directory Structure
    # ==========================================
    Write-Step "Fase 4: Creando estructura de directorios en $HOMELAB_ROOT..."

    $dirs = @(
        "data\portainer",
        "data\homepage\config",
        "data\infisical\db",
        "data\infisical\redis",
        "data\jellyfin\config",
        "data\jellyfin\cache",
        "data\jellyseerr\config",
        "data\sonarr\config",
        "data\radarr\config",
        "data\prowlarr\config",
        "data\bazarr\config",
        "data\qbittorrent\config",
        "data\stirling-pdf\data",
        "data\stirling-pdf\config",
        "data\stirling-pdf\custom",
        "media\movies",
        "media\series",
        "media\music",
        "media\downloads",
        "backups\restic-repo"
    )

    foreach ($dir in $dirs) {
        $path = Join-Path $HOMELAB_ROOT $dir
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    Write-Success "Directorios creados exitosamente."

    # ==========================================
    # Fase 5: Copy Configs
    # ==========================================
    Write-Step "Fase 5: Copiando configuraciones..."

    # Homepage
    $hpSource = Join-Path $SCRIPT_DIR "configs\homepage\*.yaml"
    $hpDest = Join-Path $HOMELAB_ROOT "data\homepage\config\"
    if (Test-Path (Join-Path $SCRIPT_DIR "configs\homepage")) {
        Copy-Item -Path $hpSource -Destination $hpDest -Force
    }

    Write-Success "Configuraciones copiadas."

    # ==========================================
    # Fase 6: Deploy Stacks
    # ==========================================
    Write-Step "Fase 6: Desplegando Stacks de Docker Compose..."

    # Crear red Docker homelab si no existe
    $existingNet = docker network ls --filter name=^homelab$ --format '{{.Name}}'
    if (-not $existingNet) {
        $null = docker network create homelab
    }

    function Deploy-Stack {
        param([string]$StackPath, [string]$Index, [string]$Services = "")
        Write-Host "[$Index/6] Desplegando $StackPath..." -ForegroundColor Cyan
        $composeFile = Join-Path $SCRIPT_DIR "$StackPath\docker-compose.yml"
        if (Test-Path $composeFile) {
            if ($Services) {
                $serviceList = $Services -split ' '
                & docker compose --env-file "$ENV_FILE" -f "$composeFile" up -d --remove-orphans @serviceList
            } else {
                & docker compose --env-file "$ENV_FILE" -f "$composeFile" up -d --remove-orphans
            }
            Start-Sleep -Seconds 5
        } else {
            Write-WarningMsg "No se encontro el archivo compose en $StackPath"
        }
    }

    # 1. Core (Portainer, Homepage, DockerProxy)
    Deploy-Stack "stacks\core" "1"

    # 2. Secrets (Infisical)
    Deploy-Stack "stacks\secrets" "2"

    # 3. Media (Jellyfin, Jellyseerr, Sonarr, Radarr, Prowlarr, FlareSolverr, Bazarr, qBittorrent)
    Deploy-Stack "stacks\media" "3"

    # 4. Productivity (Excalidraw, Stirling-PDF)
    Deploy-Stack "stacks\productivity" "4"

    # 5. Backups (Restic)
    Deploy-Stack "stacks\backups" "5"

    # 6. AppFlowy
    Write-Host "[6/6] Desplegando AppFlowy..." -ForegroundColor Cyan
    $appflowyScript = Join-Path $SCRIPT_DIR "stacks\appflowy\install-appflowy.ps1"
    if (Test-Path $appflowyScript) {
        & $appflowyScript
    }

    Write-Success "Stacks desplegados exitosamente."

    # ==========================================
    # Fase 7: Verify Services
    # ==========================================
    Write-Step "Fase 7: Verificando estado de los servicios..."

    $containers = docker ps --format '{{.Names}}|{{.Status}}'
    $total = 0
    $running = 0

    Write-Host "`nContenedores:" -ForegroundColor Cyan
    foreach ($c in $containers) {
        $parts = $c -split '\|'
        if ($parts.Length -eq 2) {
            $total++
            $name = $parts[0]
            $status = $parts[1]
            if ($status -match "Up") {
                Write-Host "[OK] $name [$status]" -ForegroundColor Green
                $running++
            } else {
                Write-Host "[ERROR] $name [$status]" -ForegroundColor Red
            }
        }
    }
    Write-Host "`nTotal: $total - Corriendo: $running" -ForegroundColor Yellow

    # ==========================================
    # Fase 8: Generate POST-INSTALL-README.md
    # ==========================================
    Write-Step "Fase 8: Generando archivo POST-INSTALL-README.md..."

    $readmePath = Join-Path $HOMELAB_ROOT "POST-INSTALL-README.md"
    $readmeTemplatePath = Join-Path $SCRIPT_DIR "configs\POST-INSTALL-README.template.md"
    $readmeTemplate = Get-Content -Path $readmeTemplatePath -Raw -Encoding UTF8

    $readmeText = $readmeTemplate
    $readmeText = $readmeText.Replace('__HOST_IP__', $HOST_IP)
    $readmeText = $readmeText.Replace('__APPFLOWY_PASS__', $APPFLOWY_PASS_VAL)
    $readmeText = $readmeText.Replace('__HOMELAB_ROOT__', $HOMELAB_ROOT)
    $readmeText = $readmeText.Replace('__ENV_FILE__', $ENV_FILE)

    Set-Content -Path $readmePath -Value $readmeText -Encoding UTF8
    Write-Success "README generado en: $readmePath"

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "*** INSTALACION COMPLETADA EXITOSAMENTE ***" -ForegroundColor Magenta
    Write-Host "Visita tu Homepage en: http://${HOST_IP}:3001" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Magenta

} catch {
    Write-ErrorMsg "Ocurrio un error critico durante la instalacion:"
    Write-ErrorMsg $_.Exception.Message
    Write-ErrorMsg "Linea: $($_.InvocationInfo.ScriptLineNumber)"
} finally {
    $END_TIME = Get-Date
    $elapsed = $END_TIME - $START_TIME
    Write-Host "`nTiempo total de ejecucion: $($elapsed.Hours)h $($elapsed.Minutes)m $($elapsed.Seconds)s" -ForegroundColor DarkGray
}
