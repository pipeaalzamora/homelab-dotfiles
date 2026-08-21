# =============================================================
# Muestra todos los servicios del homelab con sus IPs y puertos
# =============================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "          Servicios del Homelab en Ejecucion" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker está ejecutándose
try {
    $null = docker ps 2>&1
} catch {
    Write-Host "Docker Desktop no esta ejecutandose" -ForegroundColor Red
    exit 1
}

# Obtener IP del host
$hostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*","Wi-Fi*" | 
           Where-Object { $_.IPAddress -notmatch "^169\." -and $_.PrefixOrigin -eq "Dhcp" } | 
           Select-Object -First 1).IPAddress

if (-not $hostIP) {
    $hostIP = "127.0.0.1"
}

Write-Host "IP del equipo: $hostIP" -ForegroundColor Green
Write-Host ""

# Obtener todos los contenedores en ejecución
$containers = docker ps --format "{{.Names}}`t{{.Ports}}`t{{.Status}}" 2>$null

if ([string]::IsNullOrEmpty($containers)) {
    Write-Host "No hay servicios en ejecucion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ejecuta el instalador para levantar servicios:" -ForegroundColor Cyan
    Write-Host "  .\install-local.ps1" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host "Servicios activos:" -ForegroundColor Cyan
Write-Host ""

# Parsear contenedores
$containerList = @()
$containers -split "`n" | ForEach-Object {
    $parts = $_ -split "`t"
    if ($parts.Length -ge 3) {
        $containerList += [PSCustomObject]@{
            Name = $parts[0]
            Ports = $parts[1]
            Status = $parts[2]
        }
    }
}

# Mapeo de servicios a sus descripciones y URLs
$serviceInfo = @{
    'portainer' = @{ desc = 'Portainer (Admin Docker)'; defaultPort = '9443'; protocol = 'https' }
    'npm' = @{ desc = 'Nginx Proxy Manager'; defaultPort = '8181'; protocol = 'http' }
    'adguardhome' = @{ desc = 'AdGuard Home (DNS)'; defaultPort = '8080'; protocol = 'http' }
    'homepage' = @{ desc = 'Homepage (Dashboard)'; defaultPort = '3001'; protocol = 'http' }
    'uptime-kuma' = @{ desc = 'Uptime Kuma (Monitoreo)'; defaultPort = '3001'; protocol = 'http' }
    'jellyfin' = @{ desc = 'Jellyfin (Media Server)'; defaultPort = '8096'; protocol = 'http' }
    'jellyseerr' = @{ desc = 'Jellyseerr (Peticiones)'; defaultPort = '5055'; protocol = 'http' }
    'sonarr' = @{ desc = 'Sonarr (Series)'; defaultPort = '8989'; protocol = 'http' }
    'radarr' = @{ desc = 'Radarr (Peliculas)'; defaultPort = '7878'; protocol = 'http' }
    'prowlarr' = @{ desc = 'Prowlarr (Indexers)'; defaultPort = '9696'; protocol = 'http' }
    'bazarr' = @{ desc = 'Bazarr (Subtitulos)'; defaultPort = '6767'; protocol = 'http' }
    'qbittorrent' = @{ desc = 'qBittorrent (Descargas)'; defaultPort = '8080'; protocol = 'http' }
    'nextcloud-nginx' = @{ desc = 'Nextcloud (Cloud Personal)'; defaultPort = '8082'; protocol = 'http' }
    'forgejo' = @{ desc = 'Forgejo (Git)'; defaultPort = '3004'; protocol = 'http' }
    'bookstack' = @{ desc = 'BookStack (Wiki)'; defaultPort = '6875'; protocol = 'http' }
    'n8n' = @{ desc = 'n8n (Automatizacion)'; defaultPort = '5678'; protocol = 'http' }
    'infisical' = @{ desc = 'Infisical (Secretos)'; defaultPort = '8083'; protocol = 'http' }
    'excalidraw' = @{ desc = 'Excalidraw (Diagramas)'; defaultPort = '8084'; protocol = 'http' }
    'stirling-pdf' = @{ desc = 'Stirling PDF (Editor PDF)'; defaultPort = '8085'; protocol = 'http' }
    'facto' = @{ desc = 'Facto (Finanzas)'; defaultPort = '8086'; protocol = 'http' }
    'piga' = @{ desc = 'Piga (Notas)'; defaultPort = '8087'; protocol = 'http' }
    'docat' = @{ desc = 'Docat (Docs)'; defaultPort = '8089'; protocol = 'http' }
    'everydocs-web' = @{ desc = 'EveryDocs Web'; defaultPort = '8090'; protocol = 'http' }
    'everydocs-core' = @{ desc = 'EveryDocs API'; defaultPort = '8091'; protocol = 'http' }
    'dailytxt' = @{ desc = 'DailyTxT (Diario)'; defaultPort = '8092'; protocol = 'http' }
    'wastebin' = @{ desc = 'Wastebin (Pastebin)'; defaultPort = '8093'; protocol = 'http' }
    'iguana' = @{ desc = 'Iguana (Issues/Proyectos)'; defaultPort = '8094'; protocol = 'http' }
    'authelia' = @{ desc = 'Authelia (SSO/Auth)'; defaultPort = '9091'; protocol = 'http' }
}

# Función para extraer puerto del mapeo de puertos de Docker
function Get-PublicPort {
    param([string]$portsString)
    
    if ([string]::IsNullOrEmpty($portsString)) {
        return $null
    }
    
    # Buscar patrón como "0.0.0.0:8080->80/tcp" o "127.0.0.1:8181->81/tcp"
    if ($portsString -match '(\d+\.\d+\.\d+\.\d+):(\d+)->') {
        return @{
            ip = $matches[1]
            port = $matches[2]
        }
    }
    
    return $null
}

# Agrupar por stack
$stacks = @{
    'Core' = @('portainer', 'npm', 'adguardhome', 'homepage', 'uptime-kuma')
    'Media' = @('jellyfin', 'jellyseerr', 'sonarr', 'radarr', 'prowlarr', 'bazarr', 'qbittorrent')
    'Personal' = @('nextcloud-nginx')
    'Dev' = @('forgejo', 'bookstack')
    'Tools' = @('n8n')
    'Secrets' = @('infisical')
    'Productivity' = @('excalidraw', 'stirling-pdf')
    'Finance' = @('facto')
    'Knowledge' = @('piga', 'docat', 'everydocs-web', 'everydocs-core', 'dailytxt', 'wastebin', 'iguana')
    'Security' = @('authelia')
}

$foundServices = $false

foreach ($stackName in $stacks.Keys | Sort-Object) {
    $stackServices = @()
    
    foreach ($serviceName in $stacks[$stackName]) {
        $container = $containerList | Where-Object { $_.Name -eq $serviceName }
        
        if ($container) {
            $info = $serviceInfo[$serviceName]
            $portInfo = Get-PublicPort $container.Ports
            
            if ($portInfo -and $info) {
                $ip = if ($portInfo.ip -eq "0.0.0.0") { $hostIP } else { $portInfo.ip }
                $url = "$($info.protocol)://${ip}:$($portInfo.port)"
                
                $stackServices += [PSCustomObject]@{
                    Service = $serviceName
                    Description = $info.desc
                    URL = $url
                    Status = $container.Status
                }
            }
        }
    }
    
    if ($stackServices.Count -gt 0) {
        $foundServices = $true
        Write-Host "--- $stackName ---" -ForegroundColor Yellow
        foreach ($svc in $stackServices) {
            Write-Host "  OK " -NoNewline -ForegroundColor Green
            Write-Host "$($svc.Description)" -ForegroundColor White
            Write-Host "     $($svc.URL)" -ForegroundColor Cyan
        }
        Write-Host ""
    }
}

if (-not $foundServices) {
    Write-Host "Servicios encontrados pero sin puertos expuestos" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Contenedores en ejecucion:" -ForegroundColor Cyan
    $containerList | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Consejos:" -ForegroundColor Cyan
Write-Host "  * Accede desde otros dispositivos usando: http://$hostIP`:PUERTO" -ForegroundColor Gray
Write-Host "  * Ver logs de un servicio: docker logs -f [nombre-servicio]" -ForegroundColor Gray
Write-Host "  * Detener un servicio: docker stop [nombre-servicio]" -ForegroundColor Gray
Write-Host "  * Reiniciar un servicio: docker restart [nombre-servicio]" -ForegroundColor Gray
Write-Host ""
