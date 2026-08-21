#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script de Instalación del Homelab
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
TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024))
if [ $TOTAL_RAM_GB -lt 4 ]; then
    echo -e "  ${YELLOW}⚠${NC} Memoria RAM detectada: ${TOTAL_RAM_GB}GB (Se recomiendan al menos 4GB)"
else
    echo -e "  ${GREEN}✓${NC} Memoria RAM detectada: ${TOTAL_RAM_GB}GB"
fi

FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK" -lt 20 ]; then
    echo -e "  ${YELLOW}⚠${NC} Espacio en disco disponible: ${FREE_DISK}GB (Se recomiendan al menos 20GB)"
else
    echo -e "  ${GREEN}✓${NC} Espacio en disco disponible: ${FREE_DISK}GB"
fi
echo ""

# ------------------------------------------------------------------------------
# Phase 2: Network Detection
# ------------------------------------------------------------------------------
echo -e "${CYAN}[2/8]${NC} Detectando configuración de red..."

DETECTED_IP=$(hostname -I | awk '{print $1}')
if [ -z "$DETECTED_IP" ]; then
    DETECTED_IP=$(ip route get 1 | awk '{print $7;exit}')
fi

echo -ne "  IP local detectada: ${BOLD}$DETECTED_IP${NC}. ¿Es correcta? [Y/n]: "
read -r ip_confirm
if [[ "$ip_confirm" =~ ^[Nn]$ ]]; then
    echo -ne "  Introduce la IP local manualmente: "
    read -r HOST_IP
else
    HOST_IP=$DETECTED_IP
fi
echo -e "  ${GREEN}✓${NC} Usando IP: $HOST_IP\n"

# ------------------------------------------------------------------------------
# Phase 3: Generate env/.env
# ------------------------------------------------------------------------------
echo -e "${CYAN}[3/8]${NC} Generando archivo de variables de entorno (.env)..."

HOMELAB_ROOT="/home/$(whoami)/homelab"
PUID=$(id -u)
PGID=$(id -g)

mkdir -p "$SCRIPT_DIR/env"
ENV_FILE="$SCRIPT_DIR/env/.env"

# Funciones generadoras de secretos
gen_hex() { openssl rand -hex "$1"; }
gen_b64() { openssl rand -base64 "$1" | tr -d '\n'; }
gen_alphanum() { openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$1"; }

NEXTCLOUD_ADMIN_PASSWORD=$(gen_alphanum 18)
DAILYTXT_ADMIN_PASSWORD=$(gen_alphanum 16)
QBITTORRENT_PASSWORD=$(gen_alphanum 18)
ADGUARD_PASSWORD=$(gen_alphanum 16)

cat <<EOF > "$ENV_FILE"
# ==========================================
# Configuración del Homelab
# Generado automáticamente
# ==========================================
HOMELAB_ROOT=$HOMELAB_ROOT
PUID=$PUID
PGID=$PGID
TZ=America/Santiago
HOST_IP=$HOST_IP
LOCAL_DOMAIN=home

# --- Core (AdGuard, Homepage) ---
ADGUARD_DNS_PORT=1053
ADGUARD_SETUP_PORT=3000
ADGUARD_ADMIN_PORT=8080
ADGUARD_USERNAME=pipe
ADGUARD_PASSWORD=$ADGUARD_PASSWORD
HOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001,$HOST_IP:3001

# --- Nextcloud ---
NEXTCLOUD_DB_ROOT_PASSWORD=$(gen_b64 32)
NEXTCLOUD_DB_PASSWORD=$(gen_b64 32)
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD
NEXTCLOUD_TRUSTED_DOMAINS='cloud.home homelab-pipe $HOST_IP'

# --- Forgejo ---
FORGEJO_DB_PASSWORD=$(gen_b64 32)
FORGEJO_SECRET_KEY=$(gen_hex 32)
FORGEJO_INTERNAL_TOKEN=$(gen_hex 32)
FORGEJO_DOMAIN=$HOST_IP
FORGEJO_ROOT_URL=http://$HOST_IP:3004/

# --- BookStack ---
BOOKSTACK_DB_PASSWORD=$(gen_b64 32)
BOOKSTACK_APP_KEY=base64:$(gen_b64 32)
BOOKSTACK_APP_URL=http://$HOST_IP:6875

# --- Infisical ---
INFISICAL_DB_PASSWORD=$(gen_b64 32)
INFISICAL_ENCRYPTION_KEY=$(gen_hex 16)
INFISICAL_AUTH_SECRET=$(gen_b64 32)
INFISICAL_SITE_URL=http://$HOST_IP:8083
INFISICAL_TELEMETRY_ENABLED=false

# --- Facto ---
FACTO_DB_ROOT_PASSWORD=$(gen_b64 32)
FACTO_DB_PASSWORD=$(gen_b64 32)
FACTO_SECRET=$(gen_hex 32)
FACTO_PORT=8086

# --- Piga ---
PIGA_DB_ROOT_PASSWORD=$(gen_b64 32)
PIGA_DB_PASSWORD=$(gen_b64 32)
PIGA_SECRET=$(gen_hex 32)
PIGA_PORT=8087

# --- Docat ---
DOCAT_PORT=8089
DOCAT_MAX_UPLOAD_SIZE=100M

# --- EveryDocs ---
EVERYDOCS_DB_ROOT_PASSWORD=$(gen_b64 32)
EVERYDOCS_DB_PASSWORD=$(gen_b64 32)
EVERYDOCS_SECRET_KEY_BASE=$(gen_hex 64)
EVERYDOCS_WEB_PORT=8090
EVERYDOCS_CORE_PORT=8091
EVERYDOCS_IMAGE_TAG=1.5.0
EVERYDOCS_WEB_IMAGE_TAG=1.5.0

# --- DailyTxT ---
DAILYTXT_SECRET_TOKEN=$(gen_b64 32)
DAILYTXT_ADMIN_PASSWORD=$DAILYTXT_ADMIN_PASSWORD
DAILYTXT_PORT=8092
DAILYTXT_IMAGE_TAG=2.6.2
DAILYTXT_ALLOW_REGISTRATION=true
DAILYTXT_LOGOUT_AFTER_DAYS=40
DAILYTXT_INDENT=4

# --- Wastebin ---
WASTEBIN_PASSWORD_SALT=$(gen_b64 32)
WASTEBIN_SIGNING_KEY=$(gen_b64 64)
WASTEBIN_PORT=8093
WASTEBIN_DATABASE_PATH=/data/state.db
WASTEBIN_BASE_URL=http://$HOST_IP:8093
WASTEBIN_THEME=ayu
WASTEBIN_TITLE=Wastebin
WASTEBIN_IMAGE_TAG=latest

# --- Iguana ---
IGUANA_PORT=8094
IGUANA_GIT_REF=master
IGUANA_IMAGE_TAG=local
IGUANA_VARIANT=production
IGUANA_USE_NGINX=true
IGUANA_LANG=es-cl

# --- Authelia ---
AUTHELIA_JWT_SECRET=$(gen_hex 32)
AUTHELIA_SESSION_SECRET=$(gen_hex 32)
AUTHELIA_STORAGE_ENCRYPTION_KEY=$(gen_hex 32)
AUTHELIA_PORT=9091

# --- Restic ---
RESTIC_PASSWORD=$(gen_b64 32)
RESTIC_REPOSITORY=local:/mnt/restic-repo

# --- Media (qBittorrent) ---
QBITTORRENT_PASSWORD=$QBITTORRENT_PASSWORD

EOF

echo -e "  ${GREEN}✓${NC} Archivo env/.env generado con éxito.\n"

# ------------------------------------------------------------------------------
# Phase 4: Create Directory Structure
# ------------------------------------------------------------------------------
echo -e "${CYAN}[4/8]${NC} Creando estructura de directorios en $HOMELAB_ROOT..."

mkdir -p "$HOMELAB_ROOT/data/portainer"
mkdir -p "$HOMELAB_ROOT/data/adguard/work" "$HOMELAB_ROOT/data/adguard/conf"
mkdir -p "$HOMELAB_ROOT/data/homepage/config"
mkdir -p "$HOMELAB_ROOT/data/jellyfin/config" "$HOMELAB_ROOT/data/jellyfin/cache"
mkdir -p "$HOMELAB_ROOT/data/jellyseerr/config"
mkdir -p "$HOMELAB_ROOT/data/sonarr/config"
mkdir -p "$HOMELAB_ROOT/data/radarr/config"
mkdir -p "$HOMELAB_ROOT/data/prowlarr/config"
mkdir -p "$HOMELAB_ROOT/data/bazarr/config"
mkdir -p "$HOMELAB_ROOT/data/qbittorrent/config"
mkdir -p "$HOMELAB_ROOT/data/nextcloud/db" "$HOMELAB_ROOT/data/nextcloud/html"
mkdir -p "$HOMELAB_ROOT/data/forgejo/db" "$HOMELAB_ROOT/data/forgejo/data"
mkdir -p "$HOMELAB_ROOT/data/bookstack/db" "$HOMELAB_ROOT/data/bookstack/data"
mkdir -p "$HOMELAB_ROOT/data/facto/db" "$HOMELAB_ROOT/data/facto/config"
mkdir -p "$HOMELAB_ROOT/data/piga/db" "$HOMELAB_ROOT/data/piga/app"
mkdir -p "$HOMELAB_ROOT/data/docat"
mkdir -p "$HOMELAB_ROOT/data/everydocs/db" "$HOMELAB_ROOT/data/everydocs/files" "$HOMELAB_ROOT/data/everydocs/config"
mkdir -p "$HOMELAB_ROOT/data/dailytxt"
mkdir -p "$HOMELAB_ROOT/data/wastebin"
mkdir -p "$HOMELAB_ROOT/data/iguana"
mkdir -p "$HOMELAB_ROOT/data/infisical/db" "$HOMELAB_ROOT/data/infisical/redis"
mkdir -p "$HOMELAB_ROOT/data/authelia/config"
mkdir -p "$HOMELAB_ROOT/data/stirling-pdf/data" "$HOMELAB_ROOT/data/stirling-pdf/config" "$HOMELAB_ROOT/data/stirling-pdf/custom"
mkdir -p "$HOMELAB_ROOT/media/movies" "$HOMELAB_ROOT/media/series" "$HOMELAB_ROOT/media/music" "$HOMELAB_ROOT/media/downloads"
mkdir -p "$HOMELAB_ROOT/cloud/nextcloud-data"
mkdir -p "$HOMELAB_ROOT/backups/restic-repo"
mkdir -p "$HOMELAB_ROOT/homelab/personal"

sudo chown -R "$PUID:$PGID" "$HOMELAB_ROOT"

echo -e "  ${GREEN}✓${NC} Directorios creados y permisos asignados.\n"

# ------------------------------------------------------------------------------
# Phase 5: Copy Configs
# ------------------------------------------------------------------------------
echo -e "${CYAN}[5/8]${NC} Copiando archivos de configuración iniciales..."

if [ -d "$SCRIPT_DIR/configs/homepage" ]; then
    cp "$SCRIPT_DIR/configs/homepage/"*.yaml "$HOMELAB_ROOT/data/homepage/config/" 2>/dev/null || true
    # Reemplazar localhost por HOST_IP en homepage
    if [ -f "$HOMELAB_ROOT/data/homepage/config/services.yaml" ]; then
        sed -i "s/localhost/$HOST_IP/g" "$HOMELAB_ROOT/data/homepage/config/services.yaml"
    fi
    if [ -f "$HOMELAB_ROOT/data/homepage/config/settings.yaml" ]; then
        sed -i "s/localhost/$HOST_IP/g" "$HOMELAB_ROOT/data/homepage/config/settings.yaml"
    fi
fi

if [ -f "$SCRIPT_DIR/configs/authelia/configuration.yml" ]; then
    cp "$SCRIPT_DIR/configs/authelia/configuration.yml" "$HOMELAB_ROOT/data/authelia/config/"
fi
if [ -f "$SCRIPT_DIR/configs/authelia/users_database.yml" ]; then
    cp "$SCRIPT_DIR/configs/authelia/users_database.yml" "$HOMELAB_ROOT/data/authelia/config/"
fi

if [ -f "$SCRIPT_DIR/configs/everydocs/everydocs-web-config.js" ]; then
    cp "$SCRIPT_DIR/configs/everydocs/everydocs-web-config.js" "$HOMELAB_ROOT/data/everydocs/config/"
    sed -i "s/localhost:8091/$HOST_IP:8091/g" "$HOMELAB_ROOT/data/everydocs/config/everydocs-web-config.js"
fi

if [ -f "$SCRIPT_DIR/configs/facto/accounting-config.yml" ]; then
    cp "$SCRIPT_DIR/configs/facto/accounting-config.yml" "$HOMELAB_ROOT/data/facto/config/"
fi

if [ -f "$SCRIPT_DIR/stacks/personal/nextcloud-nginx.conf" ]; then
    cp "$SCRIPT_DIR/stacks/personal/nextcloud-nginx.conf" "$HOMELAB_ROOT/homelab/personal/"
fi

echo -e "  ${GREEN}✓${NC} Configuraciones copiadas.\n"

# ------------------------------------------------------------------------------
# Phase 6: Deploy Stacks
# ------------------------------------------------------------------------------
echo -e "${CYAN}[6/8]${NC} Desplegando servicios con Docker Compose..."

# Crear red
docker network create homelab >/dev/null 2>&1 || true

deploy_stack() {
    local name="$1"
    local compose_file="$2"
    shift 2
    echo -e "  Desplegando ${BOLD}$name${NC}..."
    if [ -f "$compose_file" ]; then
        if [ $# -gt 0 ]; then
            docker compose --env-file "$ENV_FILE" -f "$compose_file" up -d "$@"
        else
            docker compose --env-file "$ENV_FILE" -f "$compose_file" up -d
        fi
        sleep 5 # Espera para permitir inicialización
    else
        echo -e "  ${YELLOW}⚠ Archivo $compose_file no encontrado. Saltando.${NC}"
    fi
}

deploy_stack "Core" "$SCRIPT_DIR/stacks/core/docker-compose.yml" portainer adguard dockerproxy homepage
deploy_stack "Media" "$SCRIPT_DIR/stacks/media/docker-compose.yml"
deploy_stack "Personal" "$SCRIPT_DIR/stacks/personal/docker-compose.yml"
deploy_stack "Dev" "$SCRIPT_DIR/stacks/dev/docker-compose.yml"
deploy_stack "Secrets (Infisical)" "$SCRIPT_DIR/stacks/secrets/docker-compose.yml"
deploy_stack "Productivity" "$SCRIPT_DIR/stacks/productivity/docker-compose.yml"
deploy_stack "Security (Authelia)" "$SCRIPT_DIR/stacks/security/docker-compose.yml"

echo -e "  Inicializando base de datos para ${BOLD}Finance (Facto)${NC}..."
if [ -f "$SCRIPT_DIR/stacks/finance/docker-compose.yml" ]; then
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/finance/docker-compose.yml" up -d facto-db
    sleep 20
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/finance/docker-compose.yml" exec facto-db bin/server -DdropAndCreateNewDb || true
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/finance/docker-compose.yml" exec facto-db bin/server -DcreateAdminUser || true
    deploy_stack "Finance" "$SCRIPT_DIR/stacks/finance/docker-compose.yml"
fi

echo -e "  Inicializando base de datos para ${BOLD}Knowledge (Piga)${NC}..."
if [ -f "$SCRIPT_DIR/stacks/knowledge/docker-compose.yml" ]; then
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/knowledge/docker-compose.yml" up -d piga-db
    sleep 20
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/knowledge/docker-compose.yml" exec piga-db bin/server -DdropAndCreateNewDb || true
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/knowledge/docker-compose.yml" exec piga-db bin/server -DcreateAdminUser || true
    deploy_stack "Knowledge" "$SCRIPT_DIR/stacks/knowledge/docker-compose.yml"
fi

deploy_stack "Backups" "$SCRIPT_DIR/stacks/backups/docker-compose.yml"

echo -e "  Desplegando ${BOLD}AppFlowy${NC}..."
if [ ! -d "$HOMELAB_ROOT/appflowy" ]; then
    git clone https://github.com/AppFlowy-IO/AppFlowy-Cloud.git "$HOMELAB_ROOT/appflowy" >/dev/null 2>&1 || true
    if [ -d "$HOMELAB_ROOT/appflowy" ]; then
        cd "$HOMELAB_ROOT/appflowy"
        # Dummy .env for AppFlowy
        cat <<EOF > .env
APPFLOWY_AI_ENABLED=false
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(gen_b64 16)
GOTRUE_ADMIN_EMAIL=pipe@homelab.local
GOTRUE_ADMIN_PASSWORD=$(gen_alphanum 16)
EOF
        # Disable AI profile as requested
        touch docker-compose.override.yml
        docker compose pull && docker compose up -d
        cd - >/dev/null
    fi
fi

echo -e "  ${GREEN}✓${NC} Stacks desplegados.\n"

# ------------------------------------------------------------------------------
# Phase 7: Verify Services
# ------------------------------------------------------------------------------
echo -e "${CYAN}[7/8]${NC} Verificando estado de los servicios...\n"

TOTAL_CONTAINERS=$(docker ps -a --format '{{.Names}}' | wc -l)
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)

echo -e "${BOLD}Contenedores corriendo: $RUNNING_CONTAINERS / $TOTAL_CONTAINERS${NC}\n"

docker ps --format 'table {{.Names}}\t{{.Status}}' | while read -r line; do
    if [[ "$line" == *"Up"* ]]; then
        echo -e "✅ $line"
    elif [[ "$line" == *"NAMES"* ]]; then
        echo -e "   $line"
    else
        echo -e "❌ $line"
    fi
done

echo ""

# ------------------------------------------------------------------------------
# Phase 8: Generate POST-INSTALL-README.md
# ------------------------------------------------------------------------------
echo -e "${CYAN}[8/8]${NC} Generando POST-INSTALL-README.md..."

README_FILE="$HOMELAB_ROOT/POST-INSTALL-README.md"

cat <<EOF > "$README_FILE"
# 🚀 Homelab - Post Instalación

¡Felicidades! La instalación automatizada ha finalizado. Aquí tienes toda la información de acceso.

## 📋 Servicios Desplegados

| Service | URL | Default Credentials |
|---------|-----|--------------------|
| Homepage | http://$HOST_IP:3001 | — |
| Portainer | https://$HOST_IP:9443 | Crear admin en primer acceso |
| AdGuard Home | http://$HOST_IP:3000 | Configurar en primer acceso |
| Jellyfin | http://$HOST_IP:8096 | Configurar en primer acceso |
| Jellyseerr | http://$HOST_IP:5055 | Configurar en primer acceso |
| Sonarr | http://$HOST_IP:8989 | — |
| Radarr | http://$HOST_IP:7878 | — |
| Prowlarr | http://$HOST_IP:9696 | — |
| Bazarr | http://$HOST_IP:6767 | — |
| qBittorrent | http://$HOST_IP:8081 | admin / (ver logs) |
| Nextcloud | http://$HOST_IP:8082 | admin / $NEXTCLOUD_ADMIN_PASSWORD |
| Forgejo | http://$HOST_IP:3004 | Configurar en primer acceso |
| BookStack | http://$HOST_IP:6875 | admin@admin.com / password |
| Infisical | http://$HOST_IP:8083 | Crear cuenta en primer acceso |
| Excalidraw | http://$HOST_IP:8084 | — |
| Stirling PDF | http://$HOST_IP:8085 | — |
| Facto | http://$HOST_IP:8086 | admin / changeme |
| Piga | http://$HOST_IP:8087 | admin / changeme |
| Docat | http://$HOST_IP:8089 | — |
| EveryDocs | http://$HOST_IP:8090 | — |
| DailyTxT | http://$HOST_IP:8092 | admin / $DAILYTXT_ADMIN_PASSWORD |
| Wastebin | http://$HOST_IP:8093 | — |
| Iguana | http://$HOST_IP:8094 | Configurar en primer acceso |
| AppFlowy | http://$HOST_IP:8095 | pipe@homelab.local / (ver .env en appflowy) |
| Authelia | http://$HOST_IP:9091 | pipe / changeme |

## 📂 ¿Dónde están los archivos de configuración?
Todos los datos persistentes (volúmenes de Docker) están mapeados localmente en:
\`$HOMELAB_ROOT/data/\` y \`$HOMELAB_ROOT/media/\`.

## 🔄 ¿Cómo reiniciar un stack?
Para reiniciar un stack completo, navega al directorio del proyecto (\`$SCRIPT_DIR/stacks/<nombre_stack>\`) y ejecuta:
\`\`\`bash
docker compose --env-file ../../env/.env up -d --force-recreate
\`\`\`

## 📝 ¿Cómo ver los logs?
Para ver los logs de un contenedor en específico, utiliza:
\`\`\`bash
docker logs -f <nombre_del_contenedor>
\`\`\`

## 🔐 ¿Dónde están guardadas las contraseñas generadas?
Todas las contraseñas base de datos, claves secretas y tokens están guardados de forma segura en:
\`$SCRIPT_DIR/env/.env\`

## 🛑 ¿Cómo detener todo?
Puedes ir carpeta por carpeta y usar \`docker compose --env-file ... down\`, o alternativamente, desde Portainer detener los stacks.
EOF

echo -e "  ${GREEN}✓${NC} README generado en $README_FILE.\n"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo -e "${GREEN}${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}             Instalación completada                 ${NC}"
echo -e "${GREEN}${BOLD}             Tiempo: ${ELAPSED} segundos              ${NC}"
echo -e "${GREEN}${BOLD}====================================================${NC}\n"
echo -e "🌐 ${BOLD}Accede a tu panel central Homepage en:${NC} http://$HOST_IP:3001"
echo -e "📖 Lee el archivo ${BOLD}POST-INSTALL-README.md${NC} en $HOMELAB_ROOT para los accesos.\n"
