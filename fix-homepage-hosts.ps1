# =============================================================
# Arregla la configuración de HOMEPAGE_ALLOWED_HOSTS
# Agrega tu IP local automáticamente
# =============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Configurando HOMEPAGE_ALLOWED_HOSTS..." -ForegroundColor Cyan
Write-Host ""

$ENV_FILE = "env\.env"

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "No se encontro env\.env" -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts\generate-local-env.ps1" -ForegroundColor Yellow
    exit 1
}

# Obtener la IP local del equipo
Write-Host "Detectando IP local..." -ForegroundColor Cyan
$localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*","Wi-Fi*" | 
           Where-Object { $_.IPAddress -notmatch "^169\." -and $_.PrefixOrigin -eq "Dhcp" } | 
           Select-Object -First 1).IPAddress

if (-not $localIP) {
    Write-Host "No se pudo detectar la IP local automaticamente" -ForegroundColor Yellow
    $localIP = Read-Host "Ingresa tu IP local manualmente (ej: 192.168.1.7)"
}

Write-Host "IP local detectada: $localIP" -ForegroundColor Green
Write-Host ""

# Leer el archivo .env
$envContent = Get-Content $ENV_FILE -Raw

# Buscar la línea de HOMEPAGE_ALLOWED_HOSTS
if ($envContent -match 'HOMEPAGE_ALLOWED_HOSTS=([^\r\n]+)') {
    $currentHosts = $matches[1]
    Write-Host "Configuracion actual:" -ForegroundColor Yellow
    Write-Host "  $currentHosts" -ForegroundColor Gray
    Write-Host ""
    
    # Verificar si ya incluye la IP
    if ($currentHosts -match [regex]::Escape($localIP)) {
        Write-Host "Tu IP ($localIP) ya esta en la configuracion" -ForegroundColor Green
        Write-Host "No se necesitan cambios." -ForegroundColor Green
    } else {
        # Agregar la IP
        $newHosts = "$currentHosts,$localIP`:3001"
        $envContent = $envContent -replace "HOMEPAGE_ALLOWED_HOSTS=[^\r\n]+", "HOMEPAGE_ALLOWED_HOSTS=$newHosts"
        
        # Guardar el archivo
        $envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8 -NoNewline
        
        Write-Host "Configuracion actualizada:" -ForegroundColor Green
        Write-Host "  $newHosts" -ForegroundColor Gray
        Write-Host ""
        
        # Reiniciar Homepage
        Write-Host "Reiniciando Homepage..." -ForegroundColor Cyan
        docker compose --env-file $ENV_FILE -f stacks\core\docker-compose.yml up -d homepage 2>$null | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Listo! Ahora puedes acceder a Homepage desde:" -ForegroundColor Green
            Write-Host "  http://localhost:3001" -ForegroundColor Cyan
            Write-Host "  http://127.0.0.1:3001" -ForegroundColor Cyan
            Write-Host "  http://${localIP}:3001" -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "Configuracion actualizada pero hubo un problema al reiniciar Homepage" -ForegroundColor Yellow
            Write-Host "Reinicia manualmente con:" -ForegroundColor Yellow
            Write-Host "  docker restart homepage" -ForegroundColor White
            Write-Host ""
        }
    }
} else {
    Write-Host "No se encontro la linea HOMEPAGE_ALLOWED_HOSTS en el .env" -ForegroundColor Red
    Write-Host "Agregando configuracion..." -ForegroundColor Yellow
    
    # Agregar la línea después de ADGUARD_ADMIN_PORT
    $newLine = "`nHOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001,$localIP`:3001"
    $envContent = $envContent -replace "(ADGUARD_ADMIN_PORT=[^\r\n]+)", "`$1$newLine"
    
    # Guardar el archivo
    $envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8 -NoNewline
    
    Write-Host "Configuracion agregada" -ForegroundColor Green
    Write-Host ""
    Write-Host "Reinicia Homepage con:" -ForegroundColor Yellow
    Write-Host "  docker compose --env-file env\.env -f stacks\core\docker-compose.yml up -d homepage" -ForegroundColor White
    Write-Host ""
}
