# =============================================================
# AppFlowy (self-hosted, tipo Notion) - instalacion Windows
# https://github.com/AppFlowy-IO/AppFlowy-Cloud
#
# AppFlowy Cloud es un stack grande (~11 servicios) mantenido
# upstream. En vez de vendorizar su docker-compose (se
# desactualiza), clonamos el repo oficial y configuramos su .env.
#
# Uso:
#   .\stacks\appflowy\install-appflowy.ps1
# =============================================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_DIR "..\..\env\.env"

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "No se encontro env\.env" -ForegroundColor Red
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
$APP_DIR = "$HOMELAB_ROOT\appflowy"

# Puertos (altos para no chocar con el resto del homelab)
$HTTP_PORT = 8095
$TLS_PORT = 8447

# Host local
$HOST_IP = "localhost"
Write-Host "==> Usando host: $HOST_IP" -ForegroundColor Cyan

# --- Clonar repo si no existe ---------------------------------
if (-not (Test-Path $APP_DIR)) {
    Write-Host "==> Clonando AppFlowy-Cloud en $APP_DIR" -ForegroundColor Cyan
    git clone --depth 1 https://github.com/AppFlowy-IO/AppFlowy-Cloud.git $APP_DIR
} else {
    Write-Host "==> $APP_DIR ya existe, se omite el clone" -ForegroundColor Yellow
}

# --- Configurar .env (solo la primera vez) --------------------
if (-not (Test-Path "$APP_DIR\.env")) {
    Write-Host "==> Generando .env con secretos y credenciales seguras" -ForegroundColor Cyan
    
    function Get-RandomHex { 
        param([int]$bytes)
        $rb = New-Object byte[] $bytes
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rb)
        ($rb | ForEach-Object { $_.ToString('x2') }) -join ''
    }
    
    function Get-RandomBase64 { 
        param([int]$bytes)
        $rb = New-Object byte[] $bytes
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rb)
        [Convert]::ToBase64String($rb) -replace '[/+=]','' | Select-Object -First 1
    }

    $JWT = Get-RandomHex 32
    $PGPASS = Get-RandomHex 16
    $MINIO_KEY = Get-RandomHex 8
    $MINIO_SECRET = Get-RandomHex 24
    $ADMINPASS = (Get-RandomBase64 18).Substring(0,20)

    Copy-Item "$APP_DIR\deploy.env" "$APP_DIR\.env"
    
    # Reemplazar valores en .env
    $envContent = Get-Content "$APP_DIR\.env" -Raw
    $envContent = $envContent -replace 'FQDN=.*', "FQDN=${HOST_IP}:${HTTP_PORT}"
    $envContent = $envContent -replace 'NGINX_PORT=.*', "NGINX_PORT=${HTTP_PORT}"
    $envContent = $envContent -replace 'NGINX_TLS_PORT=.*', "NGINX_TLS_PORT=${TLS_PORT}"
    $envContent = $envContent -replace 'POSTGRES_PASSWORD=.*', "POSTGRES_PASSWORD=${PGPASS}"
    $envContent = $envContent -replace 'GOTRUE_JWT_SECRET=.*', "GOTRUE_JWT_SECRET=${JWT}"
    $envContent = $envContent -replace 'GOTRUE_ADMIN_EMAIL=.*', "GOTRUE_ADMIN_EMAIL=pipe@homelab.local"
    $envContent = $envContent -replace 'GOTRUE_ADMIN_PASSWORD=.*', "GOTRUE_ADMIN_PASSWORD=${ADMINPASS}"
    $envContent = $envContent -replace 'AWS_ACCESS_KEY=.*', "AWS_ACCESS_KEY=${MINIO_KEY}"
    $envContent = $envContent -replace 'AWS_SECRET=.*', "AWS_SECRET=${MINIO_SECRET}"
    $envContent = $envContent -replace 'PGADMIN_DEFAULT_EMAIL=.*', "PGADMIN_DEFAULT_EMAIL=pipe@homelab.local"
    $envContent = $envContent -replace 'PGADMIN_DEFAULT_PASSWORD=.*', "PGADMIN_DEFAULT_PASSWORD=${ADMINPASS}"
    
    $envContent | Out-File -FilePath "$APP_DIR\.env" -Encoding UTF8 -NoNewline

    Write-Host ""
    Write-Host "  >>> Credenciales admin de AppFlowy (guardalas):" -ForegroundColor Green
    Write-Host "      email:    pipe@homelab.local" -ForegroundColor White
    Write-Host "      password: ${ADMINPASS}" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "==> $APP_DIR\.env ya existe, se conserva" -ForegroundColor Yellow
}

# --- Override local -------------------------------------------
$overrideContent = @'
services:
  # Desactiva el servicio "ai" (requiere OPENAI_API_KEY / AZURE_OPENAI_*).
  # Para habilitarlo: pon la key en .env y usa --profile ai.
  ai:
    profiles: ["ai"]
'@

$overrideContent | Out-File -FilePath "$APP_DIR\docker-compose.override.yml" -Encoding UTF8 -NoNewline

# --- Levantar -------------------------------------------------
Write-Host "==> Descargando imagenes y levantando el stack" -ForegroundColor Cyan
docker compose --project-directory $APP_DIR `
  -f "$APP_DIR\docker-compose.yml" `
  -f "$APP_DIR\docker-compose.override.yml" `
  --env-file "$APP_DIR\.env" pull

docker compose --project-directory $APP_DIR `
  -f "$APP_DIR\docker-compose.yml" `
  -f "$APP_DIR\docker-compose.override.yml" `
  --env-file "$APP_DIR\.env" up -d --remove-orphans

Write-Host ""
Write-Host "AppFlowy listo:" -ForegroundColor Green
Write-Host "  Web:            http://${HOST_IP}:${HTTP_PORT}" -ForegroundColor Cyan
Write-Host "  Consola admin:  http://${HOST_IP}:${HTTP_PORT}/console" -ForegroundColor Cyan
Write-Host ""
Write-Host "En la app de escritorio AppFlowy: Settings -> server URL -> http://${HOST_IP}:${HTTP_PORT}" -ForegroundColor Yellow
Write-Host ""
