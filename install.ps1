<#
.SYNOPSIS
Script de instalación completa para el homelab en Windows.

.DESCRIPTION
Verifica requisitos, configura red, genera secreto .env,
crea directorios, copia configuraciones, despliega contenedores y
genera un README post-instalación.
#>

$ErrorActionPreference = "Stop"

# Variables Globales
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$HOMELAB_ROOT = Join-Path $env:USERPROFILE "homelab"
$START_TIME = Get-Date

function Write-Step {
    param([string]$Text)
    Write-Host "`n🚀 $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Text)
    Write-Host "⚠️ $Text" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
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
    Write-Host "🌟 INICIANDO INSTALACIÓN DEL HOMELAB 🌟" -ForegroundColor Magenta
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
        Write-Success "Docker Daemon en ejecución."
    } catch {
        Write-ErrorMsg "Docker Daemon no está corriendo. Inicia Docker Desktop."
        exit 1
    }

    # RAM (Advertencia si < 4GB)
    $ram = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    if ($ramGB -lt 4) {
        Write-WarningMsg "RAM detectada: $ramGB GB (menor a 4GB recomendado)."
    } else {
        Write-Success "RAM suficiente: $ramGB GB"
    }

    # Disk Free Space (Advertencia si < 20GB en C:)
    $disk = Get-PSDrive C
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    if ($freeGB -lt 20) {
        Write-WarningMsg "Espacio libre en C: $freeGB GB (menor a 20GB recomendado)."
    } else {
        Write-Success "Espacio en disco suficiente: $freeGB GB"
    }

    # ==========================================
    # Fase 2: Network Detection
    # ==========================================
    Write-Step "Fase 2: Detectando red local..."
    
    $autoIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
    
    if ($autoIp) {
        $HOST_IP = Read-Host "Se detectó la IP $autoIp. Presiona Enter para usarla o escribe otra manualmente"
        if ([string]::IsNullOrWhiteSpace($HOST_IP)) {
            $HOST_IP = $autoIp
        }
    } else {
        $HOST_IP = Read-Host "No se pudo detectar la IP automáticamente. Ingresa tu IP local"
        if ([string]::IsNullOrWhiteSpace($HOST_IP)) {
            $HOST_IP = "127.0.0.1"
        }
    }
    Write-Success "IP configurada: $HOST_IP"

    # ==========================================
    # Fase 3: Generate env/.env
    # ==========================================
    Write-Step "Fase 3: Generando env/.env con secretos seguros..."

    $ENV_DIR = Join-Path $SCRIPT_DIR "env"
    if (!(Test-Path $ENV_DIR)) { New-Item -ItemType Directory -Path $ENV_DIR -Force | Out-Null }
    $ENV_FILE = Join-Path $ENV_DIR ".env"

    $HOMELAB_ROOT_LINUX = $HOMELAB_ROOT.Replace('\', '/')

    # Generar todos los secretos
    $NC_DB_ROOT = Get-RandomB64 32
    $NC_DB_PASS = Get-RandomB64 32
    $NC_ADMIN_PASS = (Get-RandomB64 18).Substring(0, 16)

    $FORGEJO_DB_PASS = Get-RandomB64 32
    $FORGEJO_SECRET = Get-RandomHex 32
    $FORGEJO_TOKEN = Get-RandomHex 32

    $BOOKSTACK_DB_PASS = Get-RandomB64 32
    $BOOKSTACK_KEY = "base64:$(Get-RandomB64 32)"

    $INFISICAL_DB_PASS = Get-RandomB64 32
    $INFISICAL_KEY = Get-RandomHex 16
    $INFISICAL_SECRET = Get-RandomB64 32

    $FACTO_DB_ROOT = Get-RandomB64 32
    $FACTO_DB_PASS = Get-RandomB64 32
    $FACTO_SECRET_KEY = Get-RandomHex 32

    $PIGA_DB_ROOT = Get-RandomB64 32
    $PIGA_DB_PASS = Get-RandomB64 32
    $PIGA_SECRET_KEY = Get-RandomHex 32

    $EVERYDOCS_DB_ROOT = Get-RandomB64 32
    $EVERYDOCS_DB_PASS = Get-RandomB64 32
    $EVERYDOCS_SECRET = Get-RandomHex 64

    $DAILYTXT_TOKEN = Get-RandomB64 32
    $DAILYTXT_ADMIN_PASS = (Get-RandomB64 18).Substring(0, 16)

    $WASTEBIN_SALT = Get-RandomB64 32
    $WASTEBIN_KEY = Get-RandomB64 64

    $AUTHELIA_JWT = Get-RandomHex 32
    $AUTHELIA_SESS = Get-RandomHex 32
    $AUTHELIA_STORE = Get-RandomHex 32

    $RESTIC_PASS = Get-RandomB64 32
    $QBIT_PASS = (Get-RandomB64 18).Substring(0, 16)
    $ADGUARD_PASS_VAL = (Get-RandomB64 18).Substring(0, 16)
    $APPFLOWY_PASS_VAL = (Get-RandomB64 18).Substring(0, 16)

    $envTemplate = @'
# ==========================================
# HOMELAB ENVIRONMENT VARIABLES
# Generado automáticamente
# ==========================================

HOMELAB_ROOT=__HOMELAB_ROOT_LINUX__
HOST_IP=__HOST_IP__
LOCAL_DOMAIN=home
PUID=1000
PGID=1000
TZ=America/Santiago

# --- Nextcloud ---
NEXTCLOUD_DB_ROOT_PASSWORD=__NC_DB_ROOT__
NEXTCLOUD_DB_PASSWORD=__NC_DB_PASS__
NEXTCLOUD_ADMIN_PASSWORD=__NC_ADMIN_PASS__
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_TRUSTED_DOMAINS='cloud.home homelab-pipe __HOST_IP__'

# --- Forgejo ---
FORGEJO_DB_PASSWORD=__FORGEJO_DB_PASS__
FORGEJO_SECRET_KEY=__FORGEJO_SECRET__
FORGEJO_INTERNAL_TOKEN=__FORGEJO_TOKEN__
FORGEJO_DOMAIN=__HOST_IP__
FORGEJO_ROOT_URL=http://__HOST_IP__:3004/
FORGEJO_SSH_DOMAIN=__HOST_IP__

# --- BookStack ---
BOOKSTACK_DB_PASSWORD=__BOOKSTACK_DB_PASS__
BOOKSTACK_APP_KEY=__BOOKSTACK_KEY__
BOOKSTACK_APP_URL=http://__HOST_IP__:6875

# --- Infisical ---
INFISICAL_DB_PASSWORD=__INFISICAL_DB_PASS__
INFISICAL_ENCRYPTION_KEY=__INFISICAL_KEY__
INFISICAL_AUTH_SECRET=__INFISICAL_SECRET__
INFISICAL_SITE_URL=http://__HOST_IP__:8083
INFISICAL_TELEMETRY_ENABLED=false

# --- Facto ---
FACTO_DB_ROOT_PASSWORD=__FACTO_DB_ROOT__
FACTO_DB_PASSWORD=__FACTO_DB_PASS__
FACTO_SECRET=__FACTO_SECRET_KEY__
FACTO_PORT=8086

# --- Piga ---
PIGA_DB_ROOT_PASSWORD=__PIGA_DB_ROOT__
PIGA_DB_PASSWORD=__PIGA_DB_PASS__
PIGA_SECRET=__PIGA_SECRET_KEY__
PIGA_PORT=8087

# --- EveryDocs ---
EVERYDOCS_DB_ROOT_PASSWORD=__EVERYDOCS_DB_ROOT__
EVERYDOCS_DB_PASSWORD=__EVERYDOCS_DB_PASS__
EVERYDOCS_SECRET_KEY_BASE=__EVERYDOCS_SECRET__
EVERYDOCS_WEB_PORT=8090
EVERYDOCS_CORE_PORT=8091
EVERYDOCS_IMAGE_TAG=1.5.0
EVERYDOCS_WEB_IMAGE_TAG=1.5.0

# --- DailyTxT ---
DAILYTXT_SECRET_TOKEN=__DAILYTXT_TOKEN__
DAILYTXT_ADMIN_PASSWORD=__DAILYTXT_ADMIN_PASS__
DAILYTXT_PORT=8092
DAILYTXT_IMAGE_TAG=2.6.2
DAILYTXT_ALLOW_REGISTRATION=true
DAILYTXT_LOGOUT_AFTER_DAYS=40
DAILYTXT_INDENT=4

# --- Wastebin ---
WASTEBIN_PASSWORD_SALT=__WASTEBIN_SALT__
WASTEBIN_SIGNING_KEY=__WASTEBIN_KEY__
WASTEBIN_PORT=8093
WASTEBIN_DATABASE_PATH=/data/state.db
WASTEBIN_BASE_URL=http://__HOST_IP__:8093
WASTEBIN_THEME=ayu
WASTEBIN_TITLE=Wastebin
WASTEBIN_IMAGE_TAG=latest

# --- Authelia ---
AUTHELIA_JWT_SECRET=__AUTHELIA_JWT__
AUTHELIA_SESSION_SECRET=__AUTHELIA_SESS__
AUTHELIA_STORAGE_ENCRYPTION_KEY=__AUTHELIA_STORE__
AUTHELIA_PORT=9091

# --- Backups (Restic) ---
RESTIC_PASSWORD=__RESTIC_PASS__
RESTIC_REPOSITORY=local:/mnt/restic-repo

# --- Torrent ---
QBITTORRENT_PASSWORD=__QBIT_PASS__

# --- AdGuard Home ---
ADGUARD_DNS_PORT=1053
ADGUARD_SETUP_PORT=3000
ADGUARD_ADMIN_PORT=8080
ADGUARD_USERNAME=pipe
ADGUARD_PASSWORD=__ADGUARD_PASS_VAL__

# --- Homepage ---
HOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001,__HOST_IP__:3001

# --- Docat ---
DOCAT_PORT=8089
DOCAT_MAX_UPLOAD_SIZE=100M

# --- Iguana ---
IGUANA_PORT=8094
IGUANA_GIT_REF=master
IGUANA_IMAGE_TAG=local
IGUANA_VARIANT=production
IGUANA_USE_NGINX=true
IGUANA_LANG=es-cl
'@

    $envText = $envTemplate
    $envText = $envText.Replace('__HOMELAB_ROOT_LINUX__', $HOMELAB_ROOT_LINUX)
    $envText = $envText.Replace('__HOST_IP__', $HOST_IP)
    $envText = $envText.Replace('__NC_DB_ROOT__', $NC_DB_ROOT)
    $envText = $envText.Replace('__NC_DB_PASS__', $NC_DB_PASS)
    $envText = $envText.Replace('__NC_ADMIN_PASS__', $NC_ADMIN_PASS)
    $envText = $envText.Replace('__FORGEJO_DB_PASS__', $FORGEJO_DB_PASS)
    $envText = $envText.Replace('__FORGEJO_SECRET__', $FORGEJO_SECRET)
    $envText = $envText.Replace('__FORGEJO_TOKEN__', $FORGEJO_TOKEN)
    $envText = $envText.Replace('__BOOKSTACK_DB_PASS__', $BOOKSTACK_DB_PASS)
    $envText = $envText.Replace('__BOOKSTACK_KEY__', $BOOKSTACK_KEY)
    $envText = $envText.Replace('__INFISICAL_DB_PASS__', $INFISICAL_DB_PASS)
    $envText = $envText.Replace('__INFISICAL_KEY__', $INFISICAL_KEY)
    $envText = $envText.Replace('__INFISICAL_SECRET__', $INFISICAL_SECRET)
    $envText = $envText.Replace('__FACTO_DB_ROOT__', $FACTO_DB_ROOT)
    $envText = $envText.Replace('__FACTO_DB_PASS__', $FACTO_DB_PASS)
    $envText = $envText.Replace('__FACTO_SECRET_KEY__', $FACTO_SECRET_KEY)
    $envText = $envText.Replace('__PIGA_DB_ROOT__', $PIGA_DB_ROOT)
    $envText = $envText.Replace('__PIGA_DB_PASS__', $PIGA_DB_PASS)
    $envText = $envText.Replace('__PIGA_SECRET_KEY__', $PIGA_SECRET_KEY)
    $envText = $envText.Replace('__EVERYDOCS_DB_ROOT__', $EVERYDOCS_DB_ROOT)
    $envText = $envText.Replace('__EVERYDOCS_DB_PASS__', $EVERYDOCS_DB_PASS)
    $envText = $envText.Replace('__EVERYDOCS_SECRET__', $EVERYDOCS_SECRET)
    $envText = $envText.Replace('__DAILYTXT_TOKEN__', $DAILYTXT_TOKEN)
    $envText = $envText.Replace('__DAILYTXT_ADMIN_PASS__', $DAILYTXT_ADMIN_PASS)
    $envText = $envText.Replace('__WASTEBIN_SALT__', $WASTEBIN_SALT)
    $envText = $envText.Replace('__WASTEBIN_KEY__', $WASTEBIN_KEY)
    $envText = $envText.Replace('__AUTHELIA_JWT__', $AUTHELIA_JWT)
    $envText = $envText.Replace('__AUTHELIA_SESS__', $AUTHELIA_SESS)
    $envText = $envText.Replace('__AUTHELIA_STORE__', $AUTHELIA_STORE)
    $envText = $envText.Replace('__RESTIC_PASS__', $RESTIC_PASS)
    $envText = $envText.Replace('__QBIT_PASS__', $QBIT_PASS)
    $envText = $envText.Replace('__ADGUARD_PASS_VAL__', $ADGUARD_PASS_VAL)

    Set-Content -Path $ENV_FILE -Value $envText -Encoding UTF8
    Write-Success "Archivo .env generado correctamente."

    # ==========================================
    # Fase 4: Create Directory Structure
    # ==========================================
    Write-Step "Fase 4: Creando estructura de directorios en $HOMELAB_ROOT..."

    $dirs = @(
        "data\portainer",
        "data\adguard\work",
        "data\adguard\conf",
        "data\homepage\config",
        "data\jellyfin\config",
        "data\jellyfin\cache",
        "data\jellyseerr\config",
        "data\sonarr\config",
        "data\radarr\config",
        "data\prowlarr\config",
        "data\bazarr\config",
        "data\qbittorrent\config",
        "data\nextcloud\db",
        "data\nextcloud\html",
        "data\forgejo\db",
        "data\forgejo\data",
        "data\bookstack\db",
        "data\bookstack\data",
        "data\facto\db",
        "data\facto\config",
        "data\piga\db",
        "data\piga\app",
        "data\docat",
        "data\everydocs\db",
        "data\everydocs\files",
        "data\everydocs\config",
        "data\dailytxt",
        "data\wastebin",
        "data\iguana",
        "data\infisical\db",
        "data\infisical\redis",
        "data\authelia\config",
        "data\stirling-pdf\data",
        "data\stirling-pdf\config",
        "data\stirling-pdf\custom",
        "media\movies",
        "media\series",
        "media\music",
        "media\downloads",
        "cloud\nextcloud-data",
        "backups\restic-repo",
        "homelab\personal"
    )

    foreach ($dir in $dirs) {
        $path = Join-Path $HOMELAB_ROOT $dir
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    Write-Success "Directorios creados exitosamente."

    # ==========================================
    # Fase 5: Copy Configs
    # ==========================================
    Write-Step "Fase 5: Copiando y adaptando configuraciones..."

    function Copy-And-Replace {
        param($Source, $Destination)
        if (Test-Path $Source) {
            Copy-Item -Path $Source -Destination $Destination -Force
        } else {
            Write-WarningMsg "No se encontró $Source"
        }
    }

    # Homepage
    $hpSource = Join-Path $SCRIPT_DIR "configs\homepage\*.yaml"
    $hpDest = Join-Path $HOMELAB_ROOT "data\homepage\config\"
    if (Test-Path (Join-Path $SCRIPT_DIR "configs\homepage")) {
        Copy-Item -Path $hpSource -Destination $hpDest -Force
        $svcYaml = Join-Path $hpDest "services.yaml"
        if (Test-Path $svcYaml) {
            $content = Get-Content $svcYaml -Raw
            $content = $content -replace 'localhost', $HOST_IP
            $content = $content -replace '192.168.1.7', $HOST_IP
            Set-Content -Path $svcYaml -Value $content -Encoding UTF8
        }
    }

    # Authelia
    $authSourceDir = Join-Path $SCRIPT_DIR "configs\authelia"
    $authDestDir = Join-Path $HOMELAB_ROOT "data\authelia\config\"
    Copy-And-Replace (Join-Path $authSourceDir "configuration.yml") $authDestDir
    Copy-And-Replace (Join-Path $authSourceDir "users_database.yml") $authDestDir

    # EveryDocs
    $edSource = Join-Path $SCRIPT_DIR "configs\everydocs\everydocs-web-config.js"
    $edDest = Join-Path $HOMELAB_ROOT "data\everydocs\config\everydocs-web-config.js"
    if (Test-Path $edSource) {
        $content = Get-Content $edSource -Raw
        $content = $content -replace 'localhost:8091', "$HOST_IP:8091"
        Set-Content -Path $edDest -Value $content -Encoding UTF8
    }

    # Facto
    $factoSource = Join-Path $SCRIPT_DIR "configs\facto\accounting-config.yml"
    $factoDestDir = Join-Path $HOMELAB_ROOT "data\facto\config\"
    Copy-And-Replace $factoSource $factoDestDir

    # Nextcloud Nginx
    $ncSource = Join-Path $SCRIPT_DIR "stacks\personal\nextcloud-nginx.conf"
    $ncDestDir = Join-Path $HOMELAB_ROOT "homelab\personal\"
    Copy-And-Replace $ncSource $ncDestDir

    Write-Success "Configuraciones copiadas y adaptadas."

    # ==========================================
    # Fase 6: Deploy Stacks
    # ==========================================
    Write-Step "Fase 6: Desplegando Stacks de Docker Compose..."

    # Crear red
    $null = docker network create homelab 2>&1

    function Deploy-Stack {
        param([string]$StackPath, [string]$Index, [string]$Services = "")
        Write-Host "[$Index/11] Desplegando $StackPath..." -ForegroundColor Cyan
        $composeFile = Join-Path $SCRIPT_DIR "$StackPath\docker-compose.yml"
        if (Test-Path $composeFile) {
            if ($Services) {
                $serviceList = $Services -split ' '
                & docker compose --env-file "$ENV_FILE" -f "$composeFile" up -d @serviceList
            } else {
                & docker compose --env-file "$ENV_FILE" -f "$composeFile" up -d
            }
            Start-Sleep -Seconds 5
        } else {
            Write-WarningMsg "No se encontró el archivo compose en $StackPath"
        }
    }

    Deploy-Stack "stacks\core" "1" "portainer adguard dockerproxy homepage"
    Deploy-Stack "stacks\media" "2"
    Deploy-Stack "stacks\personal" "3"
    Deploy-Stack "stacks\dev" "4"
    Deploy-Stack "stacks\secrets" "5"
    Deploy-Stack "stacks\productivity" "6"
    Deploy-Stack "stacks\security" "7"
    
    # Finance (Facto)
    Write-Host "[8/11] Inicializando y desplegando Facto..." -ForegroundColor Cyan
    $factoScript = Join-Path $SCRIPT_DIR "stacks\finance\init-facto.ps1"
    if (Test-Path $factoScript) {
        & $factoScript
    } else {
        Deploy-Stack "stacks\finance" "8"
    }

    # Knowledge (Piga + otros)
    Write-Host "[9/11] Inicializando y desplegando Piga y Knowledge..." -ForegroundColor Cyan
    $pigaScript = Join-Path $SCRIPT_DIR "stacks\knowledge\init-piga.ps1"
    if (Test-Path $pigaScript) {
        & $pigaScript
    } else {
        Deploy-Stack "stacks\knowledge" "9"
    }

    Deploy-Stack "stacks\backups" "10"

    # AppFlowy
    Write-Host "[11/11] Desplegando AppFlowy..." -ForegroundColor Cyan
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
                Write-Host "✅ $name ($status)" -ForegroundColor Green
                $running++
            } else {
                Write-Host "❌ $name ($status)" -ForegroundColor Red
            }
        }
    }
    Write-Host "`nTotal: $total | Corriendo: $running" -ForegroundColor Yellow

    # ==========================================
    # Fase 8: Generate POST-INSTALL-README.md
    # ==========================================
    Write-Step "Fase 8: Generando archivo POST-INSTALL-README.md..."

    $readmePath = Join-Path $HOMELAB_ROOT "POST-INSTALL-README.md"
    $readmeTemplate = @'
# 🚀 Homelab - Post Instalación

¡Tu homelab ha sido desplegado exitosamente! Aquí tienes la información necesaria para acceder y administrar tus servicios.

## 🌐 Servicios Disponibles

| Servicio | URL | Credenciales por Defecto |
|---------|-----|--------------------|
| **Homepage** | http://__HOST_IP__:3001 | - |
| **Portainer** | https://__HOST_IP__:9443 | Crear admin en primer acceso |
| **AdGuard Home** | http://__HOST_IP__:3000 | Configurar en primer acceso |
| **Jellyfin** | http://__HOST_IP__:8096 | Configurar en primer acceso |
| **Jellyseerr** | http://__HOST_IP__:5055 | Configurar en primer acceso |
| **Sonarr** | http://__HOST_IP__:8989 | - |
| **Radarr** | http://__HOST_IP__:7878 | - |
| **Prowlarr** | http://__HOST_IP__:9696 | - |
| **Bazarr** | http://__HOST_IP__:6767 | - |
| **qBittorrent** | http://__HOST_IP__:8081 | admin / (ver logs) |
| **Nextcloud** | http://__HOST_IP__:8082 | admin / __NC_ADMIN_PASS__ |
| **Forgejo** | http://__HOST_IP__:3004 | Configurar en primer acceso |
| **BookStack** | http://__HOST_IP__:6875 | admin@admin.com / password |
| **Infisical** | http://__HOST_IP__:8083 | Crear cuenta en primer acceso |
| **Excalidraw** | http://__HOST_IP__:8084 | - |
| **Stirling PDF** | http://__HOST_IP__:8085 | - |
| **Facto** | http://__HOST_IP__:8086 | admin / changeme |
| **Piga** | http://__HOST_IP__:8087 | admin / changeme |
| **Docat** | http://__HOST_IP__:8089 | - |
| **EveryDocs** | http://__HOST_IP__:8090 | - |
| **DailyTxT** | http://__HOST_IP__:8092 | admin / __DAILYTXT_ADMIN_PASS__ |
| **Wastebin** | http://__HOST_IP__:8093 | - |
| **Iguana** | http://__HOST_IP__:8094 | Configurar en primer acceso |
| **AppFlowy** | http://__HOST_IP__:8095 | pipe@homelab.local / __APPFLOWY_PASS__ |
| **Authelia** | http://__HOST_IP__:9091 | pipe / changeme |

## 📁 Archivos de Configuración
- Los volúmenes y configuraciones se encuentran en: __HOMELAB_ROOT__\data
- Las contraseñas de las bases de datos y secretos están en: __ENV_FILE__

## 🔄 Cómo reiniciar un stack
Ve a la carpeta del repositorio y ejecuta:
docker compose --env-file env\.env -f stacks\<nombre>\docker-compose.yml down
docker compose --env-file env\.env -f stacks\<nombre>\docker-compose.yml up -d

## 📝 Ver logs
Para ver los logs de un contenedor específico:
docker logs -f <nombre_del_contenedor>
'@

    $readmeText = $readmeTemplate
    $readmeText = $readmeText.Replace('__HOST_IP__', $HOST_IP)
    $readmeText = $readmeText.Replace('__NC_ADMIN_PASS__', $NC_ADMIN_PASS)
    $readmeText = $readmeText.Replace('__DAILYTXT_ADMIN_PASS__', $DAILYTXT_ADMIN_PASS)
    $readmeText = $readmeText.Replace('__APPFLOWY_PASS__', $APPFLOWY_PASS_VAL)
    $readmeText = $readmeText.Replace('__HOMELAB_ROOT__', $HOMELAB_ROOT)
    $readmeText = $readmeText.Replace('__ENV_FILE__', $ENV_FILE)

    Set-Content -Path $readmePath -Value $readmeText -Encoding UTF8
    Write-Success "README generado en: $readmePath"

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE 🎉" -ForegroundColor Magenta
    Write-Host "Visita tu Homepage en: http://${HOST_IP}:3001" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Magenta

} catch {
    Write-ErrorMsg "Ocurrió un error crítico durante la instalación:"
    Write-ErrorMsg $_.Exception.Message
    Write-ErrorMsg "Línea: $($_.InvocationInfo.ScriptLineNumber)"
} finally {
    $END_TIME = Get-Date
    $elapsed = $END_TIME - $START_TIME
    Write-Host "`nTiempo total de ejecución: $($elapsed.Hours)h $($elapsed.Minutes)m $($elapsed.Seconds)s" -ForegroundColor DarkGray
}
'@
