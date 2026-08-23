#!/usr/bin/env bash
# =============================================================
# AppFlowy (self-hosted, tipo Notion) — instalación
# https://github.com/AppFlowy-IO/AppFlowy-Cloud
#
# AppFlowy Cloud es un stack grande (~11 servicios) mantenido
# upstream. En vez de vendorizar su docker-compose (se
# desactualiza), clonamos el repo oficial y configuramos su .env.
#
# Uso:
#   bash stacks/appflowy/install-appflowy.sh
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../../env/.env"
source "$ENV_FILE"
HOMELAB_ROOT=${HOMELAB_ROOT:-/home/pipeaalzamora/homelab}

APP_DIR="$HOMELAB_ROOT/appflowy"

# Puertos (altos para no chocar con el resto del homelab)
HTTP_PORT=8095
TLS_PORT=8447

# Host local
HOST_IP="localhost"
echo "==> Usando host: $HOST_IP"

# --- Clonar repo si no existe ---------------------------------
if [[ ! -d "$APP_DIR" ]]; then
  echo "==> Clonando AppFlowy-Cloud en $APP_DIR"
  git clone --depth 1 https://github.com/AppFlowy-IO/AppFlowy-Cloud.git "$APP_DIR"
else
  echo "==> $APP_DIR ya existe, se omite el clone"
fi

# --- Configurar .env (solo la primera vez) --------------------
if [[ ! -f "$APP_DIR/.env" ]]; then
  echo "==> Generando .env con secretos y credenciales seguras"
  JWT=$(openssl rand -hex 32)
  PGPASS=$(openssl rand -hex 16)
  MINIO_KEY=$(openssl rand -hex 8)
  MINIO_SECRET=$(openssl rand -hex 24)
  ADMINPASS=$(openssl rand -base64 18 | tr -d '/+=' | head -c 20)

  cp "$APP_DIR/deploy.env" "$APP_DIR/.env"
  sed -i \
    -e "s#^FQDN=.*#FQDN=${HOST_IP}:${HTTP_PORT}#" \
    -e "s#^NGINX_PORT=.*#NGINX_PORT=${HTTP_PORT}#" \
    -e "s#^NGINX_TLS_PORT=.*#NGINX_TLS_PORT=${TLS_PORT}#" \
    -e "s#^POSTGRES_PASSWORD=.*#POSTGRES_PASSWORD=${PGPASS}#" \
    -e "s#^GOTRUE_JWT_SECRET=.*#GOTRUE_JWT_SECRET=${JWT}#" \
    -e "s#^GOTRUE_ADMIN_EMAIL=.*#GOTRUE_ADMIN_EMAIL=pipe@homelab.local#" \
    -e "s#^GOTRUE_ADMIN_PASSWORD=.*#GOTRUE_ADMIN_PASSWORD=${ADMINPASS}#" \
    -e "s#^AWS_ACCESS_KEY=.*#AWS_ACCESS_KEY=${MINIO_KEY}#" \
    -e "s#^AWS_SECRET=.*#AWS_SECRET=${MINIO_SECRET}#" \
    -e "s#^PGADMIN_DEFAULT_EMAIL=.*#PGADMIN_DEFAULT_EMAIL=pipe@homelab.local#" \
    -e "s#^PGADMIN_DEFAULT_PASSWORD=.*#PGADMIN_DEFAULT_PASSWORD=${ADMINPASS}#" \
    "$APP_DIR/.env"

  echo ""
  echo "  >>> Credenciales admin de AppFlowy (guárdalas):"
  echo "      email:    pipe@homelab.local"
  echo "      password: ${ADMINPASS}"
  echo ""
else
  echo "==> $APP_DIR/.env ya existe, se conserva"
fi

# --- Override local -------------------------------------------
# El admin_frontend hereda APPFLOWY_BASE_URL global (http://HOST_IP:8095),
# que es alcanzable desde el navegador y desde el contenedor, así que no
# necesita override. Solo desactivamos el servicio "ai".
cat > "$APP_DIR/docker-compose.override.yml" << 'OVERRIDE'
services:
  # Desactiva el servicio "ai" (requiere OPENAI_API_KEY / AZURE_OPENAI_*).
  # Para habilitarlo: pon la key en .env y usa --profile ai.
  ai:
    profiles: ["ai"]
OVERRIDE

# --- Levantar -------------------------------------------------
echo "==> Descargando imágenes y levantando el stack"
docker compose --project-directory "$APP_DIR" \
  -f "$APP_DIR/docker-compose.yml" \
  -f "$APP_DIR/docker-compose.override.yml" \
  --env-file "$APP_DIR/.env" pull
docker compose --project-directory "$APP_DIR" \
  -f "$APP_DIR/docker-compose.yml" \
  -f "$APP_DIR/docker-compose.override.yml" \
  --env-file "$APP_DIR/.env" up -d --remove-orphans

echo ""
echo "AppFlowy listo:"
echo "  Web:            http://${HOST_IP}:${HTTP_PORT}"
echo "  Consola admin:  http://${HOST_IP}:${HTTP_PORT}/console"
echo ""
echo "En la app de escritorio AppFlowy: Settings -> server URL -> http://${HOST_IP}:${HTTP_PORT}"
