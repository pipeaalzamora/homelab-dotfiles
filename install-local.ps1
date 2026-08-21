# =============================================================
# Homelab Pipe Edition — Instalación local en computador personal (Windows)
# No instala paquetes, no toca SSH, UFW ni Tailscale.
# =============================================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_DIR "env\.env"

# --- Verificar que Docker Desktop esté ejecutándose ----------
Write-Host "Verificando Docker Desktop..." -ForegroundColor Cyan
try {
    $null = docker ps 2>&1
    Write-Host "✅ Docker Desktop está ejecutándose" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ Docker Desktop no está ejecutándose o no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Soluciones:" -ForegroundColor Yellow
    Write-Host "  1. Abre Docker Desktop y espera a que inicie completamente" -ForegroundColor White
    Write-Host "  2. Si no está instalado, descárgalo de: https://www.docker.com/products/docker-desktop" -ForegroundColor White
    Write-Host "  3. Después de iniciar Docker Desktop, vuelve a ejecutar este script" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "No se encontró env\.env" -ForegroundColor Red
    Write-Host "Copia la plantilla primero:" -ForegroundColor Yellow
    Write-Host "  Copy-Item env\.env.example env\.env" -ForegroundColor Yellow
    exit 1
}

# Cargar variables de entorno desde .env
Get-Content $ENV_FILE | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

$HOMELAB_ROOT = if ($env:HOMELAB_ROOT) { $env:HOMELAB_ROOT } else { "$env:USERPROFILE\homelab" }
[Environment]::SetEnvironmentVariable("HOMELAB_ROOT", $HOMELAB_ROOT, "Process")

function Compose-Up {
    param([string]$stack)
    
    # Verificar que la red homelab existe antes de levantar cualquier stack
    $networkExists = docker network ls --filter name=^homelab$ --format '{{.Name}}' 2>$null
    if ($networkExists -ne "homelab") {
        Write-Host "Creando red Docker 'homelab'..." -ForegroundColor Cyan
        docker network create homelab 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Red 'homelab' creada exitosamente" -ForegroundColor Green
        }
    }
    
    docker compose --env-file $ENV_FILE -f "$SCRIPT_DIR\stacks\$stack\docker-compose.yml" up -d
}

function Prepare-Local {
    Write-Host "Creando estructura local en $HOMELAB_ROOT" -ForegroundColor Green
    $env:PUID = if ($env:PUID) { $env:PUID } else { "1000" }
    $env:PGID = if ($env:PGID) { $env:PGID } else { "1000" }
    $env:HOMELAB_ROOT = $HOMELAB_ROOT
    & "$SCRIPT_DIR\scripts\03-dirs.ps1"
    
    Write-Host ""
    Write-Host "Creando red Docker 'homelab'..." -ForegroundColor Cyan
    $networkExists = docker network ls --filter name=^homelab$ --format '{{.Name}}' 2>$null
    if ($networkExists -eq "homelab") {
        Write-Host "Red 'homelab' ya existe" -ForegroundColor Yellow
    } else {
        docker network create homelab 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Red 'homelab' creada exitosamente" -ForegroundColor Green
        } else {
            Write-Host "Advertencia: No se pudo crear la red 'homelab'" -ForegroundColor Yellow
        }
    }
    
    Copy-Configs
}

function Copy-Configs {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\homelab\personal" | Out-Null
    Copy-Item "$SCRIPT_DIR\stacks\personal\nextcloud-nginx.conf" "$HOMELAB_ROOT\homelab\personal\nextcloud-nginx.conf"
    
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\homepage\config" | Out-Null
    Copy-Item "$SCRIPT_DIR\configs\homepage\*.yaml" "$HOMELAB_ROOT\data\homepage\config\"
}

function Copy-Configs-Finance {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\facto\config" | Out-Null
    if (-not (Test-Path "$HOMELAB_ROOT\data\facto\config\accounting-config.yml")) {
        Copy-Item "$SCRIPT_DIR\configs\facto\accounting-config.yml" "$HOMELAB_ROOT\data\facto\config\accounting-config.yml"
        Write-Host "[Config] Facto CLP copiado." -ForegroundColor Gray
    } else {
        Write-Host "[Config] Facto CLP existente preservado." -ForegroundColor Gray
    }
}

function Run-Finance {
    Copy-Configs-Finance
    if (Test-Path "$HOMELAB_ROOT\data\facto\db\mysql") {
        Compose-Up "finance"
    } else {
        & "$SCRIPT_DIR\stacks\finance\init-facto.ps1"
    }
}

function Copy-Configs-Knowledge {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\piga\db" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\docat" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\everydocs\config" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\everydocs\db" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\everydocs\files" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\dailytxt" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\wastebin" | Out-Null
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\iguana" | Out-Null
    Copy-Item "$SCRIPT_DIR\configs\everydocs\everydocs-web-config.js" "$HOMELAB_ROOT\data\everydocs\config\everydocs-web-config.js"
    Write-Host "[Config] EveryDocs Web copiado." -ForegroundColor Gray
}

function Run-Knowledge {
    Copy-Configs-Knowledge
    if (Test-Path "$HOMELAB_ROOT\data\piga\db\mysql") {
        Compose-Up "knowledge"
    } else {
        & "$SCRIPT_DIR\stacks\knowledge\init-piga.ps1"
    }
}

function Copy-Configs-Authelia {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\authelia\config" | Out-Null
    Copy-Item "$SCRIPT_DIR\configs\authelia\configuration.yml" "$HOMELAB_ROOT\data\authelia\config\configuration.yml"
    if (-not (Test-Path "$HOMELAB_ROOT\data\authelia\config\users_database.yml")) {
        Copy-Item "$SCRIPT_DIR\configs\authelia\users_database.yml" "$HOMELAB_ROOT\data\authelia\config\users_database.yml"
        Write-Host "[Config] Authelia users_database.yml copiado." -ForegroundColor Gray
    } else {
        Write-Host "[Config] Authelia users_database.yml existente preservado." -ForegroundColor Gray
    }
}

function Run-Security {
    Copy-Configs-Authelia
    Compose-Up "security"
}

Write-Host ""
Write-Host "Homelab local en: $HOMELAB_ROOT" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) Preparar carpetas + core"
Write-Host "  2) Multimedia"
Write-Host "  3) Cloud local"
Write-Host "  4) Proyectos y wiki"
Write-Host "  5) Backups"
Write-Host "  6) Opcional: n8n"
Write-Host "  7) Opcional: Infisical (secretos)"
Write-Host "  8) Opcional: Productividad (Excalidraw + Stirling-PDF)"
Write-Host "  9) Opcional: Finanzas (Facto)"
Write-Host "  10) Opcional: Conocimiento y docs (Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana)"
Write-Host "  11) Opcional: Seguridad SSO (Authelia)"
Write-Host "  a) Ruta recomendada local (1-4)"
Write-Host ""
$OPCION = Read-Host "Opción [1-11/a]"

switch ($OPCION) {
    "1" {
        Prepare-Local
        Compose-Up "core"
    }
    "2" {
        Compose-Up "media"
    }
    "3" {
        Copy-Configs
        Compose-Up "personal"
    }
    "4" {
        Compose-Up "dev"
    }
    "5" {
        Compose-Up "backups"
    }
    "6" {
        Compose-Up "tools"
    }
    "7" {
        Compose-Up "secrets"
    }
    "8" {
        Compose-Up "productivity"
    }
    "9" {
        Run-Finance
    }
    "10" {
        Run-Knowledge
    }
    "11" {
        Run-Security
    }
    { $_ -eq "a" -or $_ -eq "A" } {
        Prepare-Local
        Compose-Up "core"
        Compose-Up "media"
        Compose-Up "personal"
        Compose-Up "dev"
    }
    default {
        Write-Host "Opción no válida." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Instalación local completada." -ForegroundColor Green
