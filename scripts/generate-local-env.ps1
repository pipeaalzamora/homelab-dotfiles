# =============================================================
# Genera env\.env para pruebas locales (Windows)
# No imprime secretos en pantalla.
# =============================================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR
$ENV_FILE = Join-Path $ROOT_DIR "env\.env"

if (Test-Path $ENV_FILE) {
    Write-Host "env\.env ya existe. No se sobreescribe." -ForegroundColor Yellow
    exit 0
}

function Get-RandomHex {
    param([int]$bytes)
    $randomBytes = New-Object byte[] $bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($randomBytes)
    return ($randomBytes | ForEach-Object { $_.ToString("x2") }) -join ''
}

function Get-RandomBase64 {
    param([int]$bytes)
    $randomBytes = New-Object byte[] $bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($randomBytes)
    return [Convert]::ToBase64String($randomBytes)
}

$homelabRoot = if ($env:USERPROFILE) { "$env:USERPROFILE\homelab" } else { "C:\Users\$env:USERNAME\homelab" }

# Obtener la IP local del equipo
$localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*","Wi-Fi*" | 
           Where-Object { $_.IPAddress -notmatch "^169\." -and $_.PrefixOrigin -eq "Dhcp" } | 
           Select-Object -First 1).IPAddress

if (-not $localIP) {
    $localIP = "192.168.1.100"  # IP de ejemplo si no se puede detectar
}

$envContent = @"
TZ=America/Santiago
PUID=1000
PGID=1000
HOMELAB_ROOT=$homelabRoot
LOCAL_DOMAIN=home
NPM_HTTP_PORT=8088
NPM_HTTPS_PORT=8443
NPM_ADMIN_PORT=8181
ADGUARD_DNS_PORT=1053
ADGUARD_SETUP_PORT=3000
ADGUARD_ADMIN_PORT=8080
HOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001,${localIP}:3001
ADGUARD_USERNAME=pipe
ADGUARD_PASSWORD=$(Get-RandomBase64 24)

TAILSCALE_AUTHKEY=

NEXTCLOUD_ADMIN_USER=pipe
NEXTCLOUD_ADMIN_PASSWORD=$(Get-RandomBase64 24)
NEXTCLOUD_DB_ROOT_PASSWORD=$(Get-RandomBase64 24)
NEXTCLOUD_DB_PASSWORD=$(Get-RandomBase64 24)
NEXTCLOUD_TRUSTED_DOMAINS='cloud.home homelab-pipe localhost'

QBITTORRENT_USERNAME=admin
QBITTORRENT_PASSWORD=$(Get-RandomBase64 18)

FORGEJO_DB_PASSWORD=$(Get-RandomBase64 24)
FORGEJO_DOMAIN=localhost
FORGEJO_ROOT_URL=http://localhost:3004/
FORGEJO_SSH_DOMAIN=localhost
FORGEJO_SECRET_KEY=$(Get-RandomHex 32)
FORGEJO_INTERNAL_TOKEN=$(Get-RandomHex 32)

BOOKSTACK_DB_PASSWORD=$(Get-RandomBase64 24)
BOOKSTACK_APP_KEY=base64:$(Get-RandomBase64 32)
BOOKSTACK_APP_URL=http://localhost:6875

N8N_DB_PASSWORD=$(Get-RandomBase64 24)
N8N_ENCRYPTION_KEY=$(Get-RandomHex 24)
N8N_BASIC_AUTH_USER=pipe
N8N_BASIC_AUTH_PASSWORD=$(Get-RandomBase64 24)

RESTIC_REPOSITORY=local:/mnt/restic-repo
RESTIC_PASSWORD=$(Get-RandomBase64 32)
B2_ACCOUNT_ID=
B2_ACCOUNT_KEY=

FACTO_DB_ROOT_PASSWORD=$(Get-RandomBase64 24)
FACTO_DB_PASSWORD=$(Get-RandomBase64 24)
FACTO_SECRET=$(Get-RandomHex 32)
FACTO_PORT=8086

PIGA_DB_ROOT_PASSWORD=$(Get-RandomBase64 24)
PIGA_DB_PASSWORD=$(Get-RandomBase64 24)
PIGA_SECRET=$(Get-RandomHex 32)
PIGA_PORT=8087

DOCAT_PORT=8089
DOCAT_MAX_UPLOAD_SIZE=100M

EVERYDOCS_DB_ROOT_PASSWORD=$(Get-RandomBase64 24)
EVERYDOCS_DB_PASSWORD=$(Get-RandomBase64 24)
EVERYDOCS_SECRET_KEY_BASE=$(Get-RandomHex 64)
EVERYDOCS_IMAGE_TAG=1.5.0
EVERYDOCS_WEB_IMAGE_TAG=1.5.0
EVERYDOCS_WEB_PORT=8090
EVERYDOCS_CORE_PORT=8091

DAILYTXT_IMAGE_TAG=2.6.2
DAILYTXT_SECRET_TOKEN=$(Get-RandomBase64 32)
DAILYTXT_ADMIN_PASSWORD=$(Get-RandomBase64 24)
DAILYTXT_ALLOW_REGISTRATION=true
DAILYTXT_LOGOUT_AFTER_DAYS=40
DAILYTXT_INDENT=4
DAILYTXT_PORT=8092

WASTEBIN_IMAGE_TAG=latest
WASTEBIN_PORT=8093
WASTEBIN_DATABASE_PATH=/data/state.db
WASTEBIN_BASE_URL=http://localhost:8093
WASTEBIN_PASSWORD_SALT=$(Get-RandomBase64 32)
WASTEBIN_SIGNING_KEY=$(Get-RandomBase64 64)
WASTEBIN_THEME=ayu
WASTEBIN_TITLE=Wastebin

IGUANA_GIT_REF=master
IGUANA_IMAGE_TAG=local
IGUANA_VARIANT=production
IGUANA_USE_NGINX=true
IGUANA_LANG=es-cl
IGUANA_PORT=8094

AUTHELIA_JWT_SECRET=$(Get-RandomHex 32)
AUTHELIA_SESSION_SECRET=$(Get-RandomHex 32)
AUTHELIA_STORAGE_ENCRYPTION_KEY=$(Get-RandomHex 32)
AUTHELIA_PORT=9091
"@

# Crear directorio env si no existe
$envDir = Join-Path $ROOT_DIR "env"
if (-not (Test-Path $envDir)) {
    New-Item -ItemType Directory -Force -Path $envDir | Out-Null
}

# Guardar el archivo
$envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8 -NoNewline

Write-Host "env\.env generado exitosamente en: $ENV_FILE" -ForegroundColor Green
Write-Host "Nota: En Windows no se gestionan permisos de archivo como en Linux" -ForegroundColor Yellow
