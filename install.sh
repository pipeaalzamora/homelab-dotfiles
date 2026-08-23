#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script de Instalación del Homelab (Linux / macOS) — Modo Localhost
# ==============================================================================

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Función para manejar errores
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n${RED}❌ Error detectado. Saliendo del script (Código de salida: $exit_code).${NC}"
    fi
}
trap cleanup EXIT

# Iniciar cronómetro
START_TIME=$(date +%s)

echo -e "${CYAN}${BOLD}====================================================${NC}"
echo -e "${CYAN}${BOLD}       Instalador de Homelab automatizado           ${NC}"
echo -e "${CYAN}${BOLD}====================================================${NC}\n"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ------------------------------------------------------------------------------
# Phase 1: Check Prerequisites
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/8]${NC} Verificando prerrequisitos..."

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $2 instalado: $("$@" 2>&1 | head -n 1)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $2 no está instalado."
        return 1
    fi
}

PREREQ_FAILED=0
check_cmd docker --version "Docker Engine" || PREREQ_FAILED=1
check_cmd docker compose version "Docker Compose v2" || PREREQ_FAILED=1
check_cmd git --version "Git" || PREREQ_FAILED=1
check_cmd openssl version "OpenSSL" || PREREQ_FAILED=1

if docker info >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Docker daemon está corriendo."
else
    echo -e "  ${RED}✗${NC} Docker daemon no está corriendo o no hay permisos."
    PREREQ_FAILED=1
fi

if [ $PREREQ_FAILED -eq 1 ]; then
    echo -e "\n${RED}Faltan dependencias críticas. Por favor instala Docker, Git y OpenSSL antes de continuar.${NC}"
    exit 1
fi

# Advertencias de recursos (RAM y Disco)
TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 8388608)
TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024))
if [ "$TOTAL_RAM_GB" -lt 4 ]; then
    echo -e "  ${YELLOW}⚠${NC} Memoria RAM detectada: ${TOTAL_RAM_GB}GB - Se recomiendan al menos 4GB"
else
    echo -e "  ${GREEN}✓${NC} Memoria RAM detectada: ${TOTAL_RAM_GB}GB"
fi

FREE_DISK=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo 50)
if [ "$FREE_DISK" -lt 20 ]; then
    echo -e "  ${YELLOW}⚠${NC} Espacio en disco disponible: ${FREE_DISK}GB - Se recomiendan al menos 20GB"
else
    echo -e "  ${GREEN}✓${NC} Espacio en disco disponible: ${FREE_DISK}GB"
fi
echo ""

# ------------------------------------------------------------------------------
# Phase 2: Network / Host Configuration (localhost)
# ------------------------------------------------------------------------------
echo -e "${CYAN}[2/8]${NC} Configurando acceso local (localhost)..."
HOST_IP="localhost"
echo -e "  ${GREEN}✓${NC} Host configurado: $HOST_IP (127.0.0.1)\n"

# ------------------------------------------------------------------------------
# Phase 3: Generate env/.env
# ------------------------------------------------------------------------------
echo -e "${CYAN}[3/8]${NC} Generando archivo de variables de entorno (.env)..."

HOMELAB_ROOT="/home/$(whoami)/homelab"
PUID=$(id -u)
PGID=$(id -g)

mkdir -p "$SCRIPT_DIR/env"
ENV_FILE="$SCRIPT_DIR/env/.env"

gen_hex() { openssl rand -hex "$1"; }
gen_b64() { openssl rand -base64 "$1" | tr -d '\n'; }
gen_alphanum() { openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$1"; }

INFISICAL_DB_PASS=$(gen_b64 32)
INFISICAL_KEY=$(gen_hex 16)
INFISICAL_SECRET=$(gen_b64 32)
QBIT_PASS=$(gen_alphanum 18)
RESTIC_PASS=$(gen_b64 32)
APPFLOWY_PASS_VAL=$(gen_alphanum 18)

cat <<EOF > "$ENV_FILE"
# ==========================================
# HOMELAB ENVIRONMENT VARIABLES
# Generado automáticamente
# ==========================================

HOMELAB_ROOT=$HOMELAB_ROOT
HOST_IP=$HOST_IP
LOCAL_DOMAIN=home
PUID=$PUID
PGID=$PGID
TZ=America/Santiago

# --- Homepage ---
HOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001

# --- Infisical (gestión de secretos) ---
INFISICAL_DB_PASSWORD=$INFISICAL_DB_PASS
INFISICAL_ENCRYPTION_KEY=$INFISICAL_KEY
INFISICAL_AUTH_SECRET=$INFISICAL_SECRET
INFISICAL_SITE_URL=http://localhost:8083
INFISICAL_TELEMETRY_ENABLED=false

# --- Torrent ---
QBITTORRENT_PASSWORD=$QBIT_PASS

# --- Backups (Restic) ---
RESTIC_PASSWORD=$RESTIC_PASS
RESTIC_REPOSITORY=local:/mnt/restic-repo
EOF

echo -e "  ${GREEN}✓${NC} Archivo env/.env generado con éxito.\n"

# ------------------------------------------------------------------------------
# Phase 4: Create Directory Structure
# ------------------------------------------------------------------------------
echo -e "${CYAN}[4/8]${NC} Creando estructura de directorios en $HOMELAB_ROOT..."

mkdir -p "$HOMELAB_ROOT/data/portainer"
mkdir -p "$HOMELAB_ROOT/data/homepage/config"
mkdir -p "$HOMELAB_ROOT/data/infisical/db" "$HOMELAB_ROOT/data/infisical/redis"
mkdir -p "$HOMELAB_ROOT/data/jellyfin/config" "$HOMELAB_ROOT/data/jellyfin/cache"
mkdir -p "$HOMELAB_ROOT/data/jellyseerr/config"
mkdir -p "$HOMELAB_ROOT/data/sonarr/config"
mkdir -p "$HOMELAB_ROOT/data/radarr/config"
mkdir -p "$HOMELAB_ROOT/data/prowlarr/config"
mkdir -p "$HOMELAB_ROOT/data/bazarr/config"
mkdir -p "$HOMELAB_ROOT/data/qbittorrent/config"
mkdir -p "$HOMELAB_ROOT/data/stirling-pdf/data" "$HOMELAB_ROOT/data/stirling-pdf/config" "$HOMELAB_ROOT/data/stirling-pdf/custom"
mkdir -p "$HOMELAB_ROOT/media/movies" "$HOMELAB_ROOT/media/series" "$HOMELAB_ROOT/media/music" "$HOMELAB_ROOT/media/downloads"
mkdir -p "$HOMELAB_ROOT/backups/restic-repo"

chown -R "$PUID:$PGID" "$HOMELAB_ROOT" 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Directorios creados exitosamente.\n"

# ------------------------------------------------------------------------------
# Phase 5: Copy Configs
# ------------------------------------------------------------------------------
echo -e "${CYAN}[5/8]${NC} Copiando archivos de configuración..."

if [ -d "$SCRIPT_DIR/configs/homepage" ]; then
    cp -r "$SCRIPT_DIR/configs/homepage/"* "$HOMELAB_ROOT/data/homepage/config/"
fi

echo -e "  ${GREEN}✓${NC} Configuraciones copiadas.\n"

# ------------------------------------------------------------------------------
# Phase 6: Deploy Stacks
# ------------------------------------------------------------------------------
echo -e "${CYAN}[6/8]${NC} Desplegando Stacks de Docker..."

docker network inspect homelab >/dev/null 2>&1 || docker network create homelab

deploy_stack() {
    local stack_dir="$1"
    local desc="$2"
    echo -e "${CYAN}--> Desplegando ${BOLD}$desc${NC}..."
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/$stack_dir/docker-compose.yml" up -d --remove-orphans
    sleep 5
}

deploy_stack "stacks/core" "Core (Portainer, Homepage, DockerProxy)"
deploy_stack "stacks/secrets" "Secrets (Infisical)"
deploy_stack "stacks/media" "Media (Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent)"
deploy_stack "stacks/productivity" "Productividad (Excalidraw, Stirling-PDF)"
deploy_stack "stacks/backups" "Backups (Restic)"

# AppFlowy
echo -e "${CYAN}--> Desplegando ${BOLD}AppFlowy${NC}..."
if [ -f "$SCRIPT_DIR/stacks/appflowy/install-appflowy.sh" ]; then
    bash "$SCRIPT_DIR/stacks/appflowy/install-appflowy.sh"
fi

echo -e "  ${GREEN}✓${NC} Todos los stacks han sido desplegados.\n"

# ------------------------------------------------------------------------------
# Phase 7: Verify Services
# ------------------------------------------------------------------------------
echo -e "${CYAN}[7/8]${NC} Verificando estado de los contenedores..."

TOTAL_CONTAINERS=0
RUNNING_CONTAINERS=0

echo -e "\n${BOLD}Estado de los servicios:${NC}"
while IFS='|' read -r name status; do
    if [ -n "$name" ]; then
        TOTAL_CONTAINERS=$((TOTAL_CONTAINERS + 1))
        if echo "$status" | grep -q "Up"; then
            echo -e "  ${GREEN}✅ $name [$status]${NC}"
            RUNNING_CONTAINERS=$((RUNNING_CONTAINERS + 1))
        else
            echo -e "  ${RED}❌ $name [$status]${NC}"
        fi
    fi
done < <(docker ps --format '{{.Names}}|{{.Status}}')

echo -e "\n  ${BOLD}Resumen:${NC} $RUNNING_CONTAINERS de $TOTAL_CONTAINERS contenedores corriendo.\n"

# ------------------------------------------------------------------------------
# Phase 8: Generate POST-INSTALL-README.md
# ------------------------------------------------------------------------------
echo -e "${CYAN}[8/8]${NC} Generando POST-INSTALL-README.md..."

README_TARGET="$HOMELAB_ROOT/POST-INSTALL-README.md"
cp "$SCRIPT_DIR/configs/POST-INSTALL-README.template.md" "$README_TARGET"
sed -i "s/__HOST_IP__/$HOST_IP/g" "$README_TARGET"
sed -i "s/__APPFLOWY_PASS__/$APPFLOWY_PASS_VAL/g" "$README_TARGET"
sed -i "s|__HOMELAB_ROOT__|$HOMELAB_ROOT|g" "$README_TARGET"
sed -i "s|__ENV_FILE__|$ENV_FILE|g" "$README_TARGET"

echo -e "  ${GREEN}✓${NC} Archivo generado en: ${BOLD}$README_TARGET${NC}\n"

END_TIME=$(date +%s)
DIFF_TIME=$((END_TIME - START_TIME))

echo -e "${GREEN}${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}     🎉 ¡Instalación Completada Exitosamente! 🎉    ${NC}"
echo -e "${GREEN}${BOLD}====================================================${NC}"
echo -e "  Dashboard Homepage: ${CYAN}http://$HOST_IP:3001${NC}"
echo -e "  Portainer:          ${CYAN}https://$HOST_IP:9443${NC}"
echo -e "  Infisical:          ${CYAN}http://$HOST_IP:8083${NC}"
echo -e "  Tiempo transcurrido: ${DIFF_TIME}s"
echo -e "${GREEN}${BOLD}====================================================${NC}\n"
