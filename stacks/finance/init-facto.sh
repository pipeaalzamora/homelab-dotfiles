#!/usr/bin/env bash
# =============================================================
# Facto — Inicialización de base de datos y usuario admin
# Ejecutar UNA SOLA VEZ antes del primer arranque del stack.
#
# Uso:
#   cd homelab-dotfiles
#   bash stacks/finance/init-facto.sh
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../../env/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No se encontró env/.env. Ejecuta desde la raíz del repo."
  exit 1
fi

source "$ENV_FILE"
HOMELAB_ROOT=${HOMELAB_ROOT:-/home/pipeaalzamora/homelab}
export HOMELAB_ROOT

COMPOSE="docker compose --env-file $ENV_FILE -f $SCRIPT_DIR/docker-compose.yml"

echo "==> Levantando base de datos (facto-db)..."
$COMPOSE up -d facto-db

echo "==> Esperando a que MariaDB esté lista (20s)..."
sleep 20

echo "==> Creando tablas..."
$COMPOSE run --rm facto sleep 5
$COMPOSE run --rm facto bin/server -DdropAndCreateNewDb

echo "==> Creando usuario admin (password: changeme — cámbialo en la UI)..."
$COMPOSE run --rm facto bin/server -DcreateAdminUser

echo ""
echo "==> Levantando Facto completo..."
$COMPOSE up -d

echo ""
echo "Facto listo en http://127.0.0.1:8086"
echo "Usuario: admin  |  Contraseña: changeme"
echo "Cambia la contraseña en: http://127.0.0.1:8086/app/useradministration"
