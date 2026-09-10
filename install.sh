#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_warn() {
    echo -e "${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}$1${NC}"
}

# Banner
echo "===================================================="
echo "       Instalador de Homelab automatizado           "
echo "===================================================="
echo ""

# Variables
HOMELAB_ROOT="${HOMELAB_ROOT:-/home/$USER/homelab}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAN_IP="${LAN_IP:-127.0.0.1}"

# =============================================================================
# [1/8] Verificando prerrequisitos
# =============================================================================
log_info "[1/8] Verificando prerrequisitos..."

check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "  ✓ $1 instalado: $($1 --version 2>&1 | head -n1)"
        return 0
    else
        log_error "  ✗ $1 no está instalado"
        return 1
    fi
}

# Verificar Docker
if ! check_command "docker"; then
    log_error "Docker no está instalado. Por favor instala Docker antes de continuar."
    exit 1
fi

# Verificar Docker daemon
if ! docker info &> /dev/null; then
    log_error "Docker daemon no está corriendo o no hay permisos."
    exit 1
fi
log_success "  ✓ Docker daemon está corriendo."

# Verificar Git
if ! check_command "git"; then
    log_error "Git no está instalado."
    exit 1
fi

# Verificar OpenSSL
if ! command -v openssl &> /dev/null; then
    log_error "OpenSSL no está instalado."
    exit 1
fi
log_success "  ✓ OpenSSL instalado: $(openssl version)"

# Verificar recursos
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
log_success "  ✓ Memoria RAM detectada: ${RAM_GB}GB"

DISK_GB=$(df -BG "$HOMELAB_ROOT" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//')
if [ -z "$DISK_GB" ]; then
    DISK_GB=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
fi
log_success "  ✓ Espacio en disco disponible: ${DISK_GB}GB"

echo ""

# =============================================================================
# [2/8] Configurando acceso local
# =============================================================================
log_info "[2/8] Configurando acceso local (localhost)..."

if ! grep -q "localhost" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts > /dev/null
fi
log_success "  ✓ Host configurado: localhost (127.0.0.1)"

echo ""

# =============================================================================
# [3/8] Generando archivo de variables de entorno (.env)
# =============================================================================
log_info "[3/8] Generando archivo de variables de entorno (.env)..."

if [ ! -d "$DOTFILES_DIR/env" ]; then
    mkdir -p "$DOTFILES_DIR/env"
fi

if [ ! -f "$DOTFILES_DIR/env/.env" ]; then
    cp "$DOTFILES_DIR/env/.env.example" "$DOTFILES_DIR/env/.env" 2>/dev/null || {
        cat > "$DOTFILES_DIR/env/.env" << 'ENVEOF'
HOMELAB_ROOT=/home/pipeaalzamora/homelab
LAN_IP=127.0.0.1
TZ=America/Santiago
PUID=1000
PGID=1000
ENVEOF
    }
    log_success "  ✓ Archivo env/.env generado con éxito."
else
    log_warn "  ⚠ env/.env ya existe, saltando."
fi

echo ""

# =============================================================================
# [4/8] Creando estructura de directorios
# =============================================================================
log_info "[4/8] Creando estructura de directorios en $HOMELAB_ROOT..."

mkdir -p "$HOMELAB_ROOT/data"
mkdir -p "$HOMELAB_ROOT/media/movies"
mkdir -p "$HOMELAB_ROOT/media/tv"
mkdir -p "$HOMELAB_ROOT/media/downloads"

log_success "  ✓ Directorios creados exitosamente."

echo ""

# =============================================================================
# [5/8] Copiando archivos de configuración
# =============================================================================
log_info "[5/8] Copiando archivos de configuración..."

if [ -d "$DOTFILES_DIR/configs" ]; then
    cp -r "$DOTFILES_DIR/configs/"* "$HOMELAB_ROOT/data/" 2>/dev/null || true
    log_success "  ✓ Configuraciones copiadas."
else
    log_warn "  ⚠ No hay configuraciones para copiar."
fi

echo ""

# =============================================================================
# [6/8] Desplegando Stacks de Docker
# =============================================================================
log_info "[6/8] Desplegando Stacks de Docker..."

export HOMELAB_ROOT
export LAN_IP

cd "$DOTFILES_DIR/stacks/core" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/secrets" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/media" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/productivity" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/reading" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/design" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/finance" && docker compose up -d --remove-orphans
cd "$DOTFILES_DIR/stacks/appflowy" && docker compose up -d --remove-orphans

log_success "  ✓ Todos los stacks desplegados."

echo ""

# =============================================================================
# [7/8] Verificando servicios
# =============================================================================
log_info "[7/8] Verificando servicios..."

sleep 5

echo ""
echo "Servicios corriendo:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20

echo ""

# =============================================================================
# [8/8] Resumen final
# =============================================================================
log_info "[8/8] Resumen final"
echo ""
echo "===================================================="
echo "          ¡Instalacion completada con éxito!        "
echo "===================================================="
echo ""
echo "Accesos rápidos (reemplaza 127.0.0.1 con tu LAN_IP):"
echo "  - Portainer:    http://127.0.0.1:3001"
echo "  - Jellyfin:     http://127.0.0.1:3002"
echo "  - Sonarr:       http://127.0.0.1:3003"
echo "  - Radarr:       http://127.0.0.1:3004"
echo "  - Prowlarr:     http://127.0.0.1:3005"
echo "  - Bazarr:       http://127.0.0.1:3006"
echo "  - Transmission: http://127.0.0.1:3007"
echo "  - Excalidraw:   http://127.0.0.1:3008"
echo "  - Stirling-PDF: http://127.0.0.1:3009"
echo "  - Infisical:    http://127.0.0.1:3010"
echo "  - BookOrbit:    http://127.0.0.1:3011"
echo "  - Penpot:       http://127.0.0.1:3012"
echo "  - Securo:       http://127.0.0.1:3013"
echo "  - AppFlowy:     http://127.0.0.1:3015"
echo "===================================================="
echo ""
echo "Notas importantes:"
echo "  1. Cambia todas las contraseñ±±±as por defecto"
echo "  2. Genera secret keys aleatorias para cada servicio"
echo ""
echo "Comandos útiles:"
echo "  docker compose ps              # Ver servicios"
echo "  docker compose logs -f <svc>   # Ver logs"
echo "  docker compose down            # Detener stack"
echo ""
echo "===================================================="