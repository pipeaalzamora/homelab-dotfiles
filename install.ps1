# =============================================================
# Homelab Pipe Edition — Script maestro de instalación (Windows)
# Ejecutar como Administrador: .\install.ps1
# =============================================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_DIR "env\.env"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🖥️  Homelab — Pipe Edition                ║" -ForegroundColor Cyan
Write-Host "║   Script de instalación automatizado        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

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

# --- Verificar que se ejecuta como Administrador -------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌  Este script debe ejecutarse como Administrador" -ForegroundColor Red
    Write-Host "    Haz clic derecho en PowerShell y selecciona 'Ejecutar como administrador'" -ForegroundColor Yellow
    exit 1
}

# --- Verificar que existe el .env ----------------------------
if (-not (Test-Path $ENV_FILE)) {
    Write-Host "❌  No se encontró env\.env" -ForegroundColor Red
    Write-Host "    Copia la plantilla y edítala primero:" -ForegroundColor Yellow
    Write-Host "    Copy-Item env\.env.example env\.env; notepad env\.env" -ForegroundColor Yellow
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

$HOMELAB_ROOT = if ($env:HOMELAB_ROOT) { $env:HOMELAB_ROOT } else { "C:\homelab" }

# --- Menú de selección ----------------------------------------
Write-Host "Selecciona el día de instalación:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1) Base local (scripts base + core)"
Write-Host "  2) Multimedia familiar (Jellyfin + arr + qBittorrent)"
Write-Host "  3) Cloud local (Nextcloud)"
Write-Host "  4) Proyectos y wiki local (Forgejo + BookStack)"
Write-Host "  5) Backups (Restic)"
Write-Host "  6) Opcional: automatización (n8n)"
Write-Host "  7) Opcional: gestión de secretos (Infisical)"
Write-Host "  8) Opcional: productividad (Excalidraw + Stirling-PDF)"
Write-Host "  9) Opcional: finanzas (Facto)"
Write-Host "  10) Opcional: conocimiento y docs (Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana)"
Write-Host "  11) Opcional: seguridad SSO (Authelia)"
Write-Host "  a) Ruta recomendada (1-5)"
Write-Host ""
$OPCION = Read-Host "Opción [1-11/a]"

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

function Run-Core {
    Write-Host ""
    Write-Host "━━━ BASE LOCAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    & "$SCRIPT_DIR\scripts\01-base.ps1"
    & "$SCRIPT_DIR\scripts\02-docker.ps1"
    & "$SCRIPT_DIR\scripts\03-dirs.ps1"
    & "$SCRIPT_DIR\scripts\04-tailscale.ps1"
    Copy-Configs-Homepage
    Write-Host ""
    Write-Host "Levantando stack core..." -ForegroundColor Green
    Compose-Up "core"
    Write-Host "✅  Base local completada." -ForegroundColor Green
}

function Run-Media {
    Write-Host ""
    Write-Host "━━━ MULTIMEDIA ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "media"
    Write-Host "✅  Multimedia completado." -ForegroundColor Green
}

function Run-Cloud {
    Write-Host ""
    Write-Host "━━━ CLOUD LOCAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Copy-Configs-Personal
    Compose-Up "personal"
    Write-Host "✅  Cloud local completado." -ForegroundColor Green
}

function Run-Dev {
    Write-Host ""
    Write-Host "━━━ PROYECTOS Y WIKI ━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "dev"
    Write-Host "✅  Proyectos y wiki completado." -ForegroundColor Green
}

function Run-Backups {
    Write-Host ""
    Write-Host "━━━ BACKUPS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "backups"
    Write-Host "✅  Backups completado." -ForegroundColor Green
}

function Run-Tools {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: N8N ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "tools"
    Write-Host "✅  n8n completado." -ForegroundColor Green
}

function Run-Secrets {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: INFISICAL ━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "secrets"
    Write-Host "✅  Infisical completado." -ForegroundColor Green
}

function Run-Productivity {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: PRODUCTIVIDAD ━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Compose-Up "productivity"
    Write-Host "✅  Excalidraw + Stirling-PDF completado." -ForegroundColor Green
}

function Run-Finance {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: FINANZAS ━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Copy-Configs-Finance
    if (Test-Path "$HOMELAB_ROOT\data\facto\db\mysql") {
        Compose-Up "finance"
    } else {
        & "$SCRIPT_DIR\stacks\finance\init-facto.ps1"
    }
    Write-Host "✅  Facto completado." -ForegroundColor Green
}

function Run-Knowledge {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: CONOCIMIENTO Y DOCS ━━━━━━━━━━━━" -ForegroundColor Cyan
    Copy-Configs-Knowledge
    if (Test-Path "$HOMELAB_ROOT\data\piga\db\mysql") {
        Compose-Up "knowledge"
    } else {
        & "$SCRIPT_DIR\stacks\knowledge\init-piga.ps1"
    }
    Write-Host "✅  Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana completado." -ForegroundColor Green
}

function Run-Security {
    Write-Host ""
    Write-Host "━━━ OPCIONAL: SEGURIDAD SSO ━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Copy-Configs-Authelia
    Compose-Up "security"
    Write-Host "✅  Authelia completado." -ForegroundColor Green
}

function Copy-Configs-Personal {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\homelab\personal" | Out-Null
    Copy-Item "$SCRIPT_DIR\stacks\personal\nextcloud-nginx.conf" "$HOMELAB_ROOT\homelab\personal\nextcloud-nginx.conf"
    Write-Host "[Config] nextcloud-nginx.conf copiado." -ForegroundColor Gray
}

function Copy-Configs-Homepage {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\homepage\config" | Out-Null
    Copy-Item "$SCRIPT_DIR\configs\homepage\*.yaml" "$HOMELAB_ROOT\data\homepage\config\"
    Write-Host "[Config] Homepage configs copiados." -ForegroundColor Gray
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

switch ($OPCION) {
    "1" { Run-Core }
    "2" { Run-Media }
    "3" { Run-Cloud }
    "4" { Run-Dev }
    "5" { Run-Backups }
    "6" { Run-Tools }
    "7" { Run-Secrets }
    "8" { Run-Productivity }
    "9" { Run-Finance }
    "10" { Run-Knowledge }
    "11" { Run-Security }
    { $_ -eq "a" -or $_ -eq "A" } {
        Run-Core
        Run-Media
        Run-Cloud
        Run-Dev
        Run-Backups
    }
    default {
        Write-Host "Opción no válida." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Instalación completada 🎉                 ║" -ForegroundColor Green
Write-Host "║   Revisa los logs: docker compose logs -f   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
