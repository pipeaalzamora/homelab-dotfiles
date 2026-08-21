# =============================================================
# Homelab Pipe Edition — Estructura de directorios (Windows)
# Crea todos los mount points antes de levantar los stacks
# =============================================================

$ErrorActionPreference = "Stop"

$PUID = if ($env:PUID) { $env:PUID } else { "1000" }
$PGID = if ($env:PGID) { $env:PGID } else { "1000" }
$HOMELAB_ROOT = if ($env:HOMELAB_ROOT) { $env:HOMELAB_ROOT } else { "C:\homelab" }

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " [03] Estructura de directorios" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Root: $HOMELAB_ROOT"

# --- Raíces principales ---------------------------------------
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\homelab" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\media" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\cloud" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\backups" | Out-Null

# --- homelab — docker-compose.yml y configs -------------------
@("core", "personal", "media", "dev", "tools", "backups", "smarthome", "security", "secrets", "productivity", "finance", "knowledge") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\homelab\$_" | Out-Null
}

# --- data — datos persistentes por servicio --------------------
# Core
@("portainer", "npm\data", "npm\letsencrypt", "adguard\work", "adguard\conf", "homepage\config", "uptime-kuma") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Personal
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\nextcloud\html" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\nextcloud\db" | Out-Null
New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\cloud\nextcloud-data" | Out-Null

# Media
@("jellyfin\config", "jellyfin\cache", "jellyseerr\config", "sonarr\config", "radarr\config", "prowlarr\config", "bazarr\config", "qbittorrent\config") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Dev
@("forgejo\data", "forgejo\db", "bookstack\data", "bookstack\db") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Tools
@("n8n\app", "n8n\db") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Secrets (Infisical)
@("infisical\db", "infisical\redis") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Productivity (Excalidraw · Stirling-PDF)
@("stirling-pdf\data", "stirling-pdf\config", "stirling-pdf\custom") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Finance (Facto)
@("facto\db", "facto\config") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Knowledge (Piga · Docat · EveryDocs · DailyTxT · Wastebin · Iguana)
@("piga\db", "docat", "everydocs\db", "everydocs\files", "everydocs\config", "dailytxt", "wastebin", "iguana") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Smarthome
@("homeassistant\config", "ollama\models", "openwebui") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# Security
@("authelia\config", "authelia\redis") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\data\$_" | Out-Null
}

# --- media — estructura multimedia ----------------------------
@("movies", "series", "music", "downloads\complete", "downloads\incomplete", "downloads\watch") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\media\$_" | Out-Null
}

# --- backups — backups locales --------------------------------
@("db", "compose", "exports", "restic-repo") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path "$HOMELAB_ROOT\backups\$_" | Out-Null
}

Write-Host ""
Write-Host "Estructura creada en: $HOMELAB_ROOT" -ForegroundColor Green
Write-Host ""
Write-Host "Directorios listos." -ForegroundColor Green
Write-Host "Nota: En Windows no se gestionan permisos PUID/PGID como en Linux" -ForegroundColor Yellow

