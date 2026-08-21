# =============================================================
# Script para crear la red Docker 'homelab'
# Ejecuta este script si ves el error:
# "network homelab declared as external, but could not be found"
# =============================================================

Write-Host ""
Write-Host "Configurando red Docker 'homelab'..." -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker está ejecutándose
try {
    $null = docker ps 2>&1
} catch {
    Write-Host "Docker Desktop no esta ejecutandose." -ForegroundColor Red
    Write-Host "Abre Docker Desktop y vuelve a intentar." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verificar si la red ya existe
$networkExists = docker network ls --filter name=^homelab$ --format '{{.Name}}' 2>$null

if ($networkExists -eq "homelab") {
    Write-Host "La red 'homelab' ya existe." -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalles de la red:" -ForegroundColor Cyan
    docker network inspect homelab --format '  ID: {{.Id}}' 2>$null
    docker network inspect homelab --format '  Driver: {{.Driver}}' 2>$null
    docker network inspect homelab --format '  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>$null
    Write-Host ""
} else {
    Write-Host "Creando red 'homelab'..." -ForegroundColor Cyan
    
    $result = docker network create homelab 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Red 'homelab' creada exitosamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Detalles de la red:" -ForegroundColor Cyan
        docker network inspect homelab --format '  ID: {{.Id}}' 2>$null
        docker network inspect homelab --format '  Driver: {{.Driver}}' 2>$null
        docker network inspect homelab --format '  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>$null
        Write-Host ""
        Write-Host "Ahora puedes ejecutar el instalador:" -ForegroundColor Cyan
        Write-Host "  .\install-local.ps1" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Error al crear la red 'homelab':" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}

# Listar todas las redes Docker
Write-Host "Redes Docker disponibles:" -ForegroundColor Cyan
docker network ls
Write-Host ""
