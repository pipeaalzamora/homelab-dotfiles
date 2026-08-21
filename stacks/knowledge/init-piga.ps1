# =============================================================
# Piga — Inicialización de base de datos y usuario admin (Windows)
# Ejecutar solo en el primer arranque. Usa -Force si quieres
# recrear la base de datos de forma explícita.
#
# Uso:
#   cd homelab-dotfiles
#   .\stacks\knowledge\init-piga.ps1
#   .\stacks\knowledge\init-piga.ps1 -Force
# =============================================================

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_DIR "..\..\env\.env"

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "No se encontró env\.env. Ejecuta desde la raíz del repo." -ForegroundColor Red
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

$DB_DIR = "$HOMELAB_ROOT\data\piga\db"
New-Item -ItemType Directory -Force -Path $DB_DIR | Out-Null

if ((Test-Path "$DB_DIR\mysql") -and -not $Force) {
    Write-Host "La base de datos de Piga ya parece inicializada en $DB_DIR." -ForegroundColor Yellow
    Write-Host "No se ejecuta drop/create para evitar pérdida de datos." -ForegroundColor Yellow
    Write-Host "Usa -Force solo si quieres recrearla." -ForegroundColor Yellow
    exit 1
}

$COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"

Write-Host "==> Levantando base de datos (piga-db)..." -ForegroundColor Cyan
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d piga-db

Write-Host "==> Esperando a que MariaDB esté lista (20s)..." -ForegroundColor Cyan
Start-Sleep -Seconds 20

Write-Host "==> Creando tablas..." -ForegroundColor Cyan
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE run --rm piga sleep 5
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE run --rm piga bin/server -DdropAndCreateNewDb

Write-Host "==> Creando usuario admin (password: changeme — cámbialo en la UI)..." -ForegroundColor Cyan
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE run --rm piga bin/server -DcreateAdminUser

Write-Host ""
Write-Host "==> Levantando Piga + Docat..." -ForegroundColor Cyan
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d

$PIGA_PORT = if ($env:PIGA_PORT) { $env:PIGA_PORT } else { "8087" }
$DOCAT_PORT = if ($env:DOCAT_PORT) { $env:DOCAT_PORT } else { "8089" }

Write-Host ""
Write-Host "Piga listo en http://127.0.0.1:$PIGA_PORT" -ForegroundColor Green
Write-Host "Usuario: admin  |  Contraseña: changeme" -ForegroundColor Yellow
Write-Host "Cambia la contraseña en: http://127.0.0.1:${PIGA_PORT}/app/useradministration" -ForegroundColor Yellow
Write-Host ""
Write-Host "Docat listo en http://127.0.0.1:$DOCAT_PORT" -ForegroundColor Green
