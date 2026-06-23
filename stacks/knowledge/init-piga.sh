#!/usr/bin/env bash
# =============================================================
# Piga — Inicialización de base de datos y usuario admin
# Ejecutar solo en el primer arranque. Usa --force si quieres
# recrear la base de datos de forma explícita.
#
# Uso:
#   cd homelab-dotfiles
#   bash stacks/knowledge/init-piga.sh
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../../env/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No se encontró env/.env. Ejecuta desde la raíz del repo."
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"
HOMELAB_ROOT=${HOMELAB_ROOT:-/home/pipeaalzamora/homelab}
export HOMELAB_ROOT

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

DB_DIR="$HOMELAB_ROOT/data/piga/db"
mkdir -p "$DB_DIR"

if [[ -d "$DB_DIR/mysql" && "$FORCE" != true ]]; then
  echo "La base de datos de Piga ya parece inicializada en $DB_DIR."
  echo "No se ejecuta drop/create para evitar pérdida de datos."
  echo "Usa --force solo si quieres recrearla."
  exit 1
fi

COMPOSE=(docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/docker-compose.yml")

echo "==> Levantando base de datos (piga-db)..."
"${COMPOSE[@]}" up -d piga-db

echo "==> Esperando a que MariaDB esté lista (20s)..."
sleep 20

echo "==> Creando tablas..."
"${COMPOSE[@]}" run --rm piga sleep 5
"${COMPOSE[@]}" run --rm piga bin/server -DdropAndCreateNewDb

echo "==> Creando usuario admin (password: changeme — cámbialo en la UI)..."
"${COMPOSE[@]}" run --rm piga bin/server -DcreateAdminUser

echo ""
echo "==> Levantando Piga + Docat..."
"${COMPOSE[@]}" up -d

echo ""
echo "Piga listo en http://127.0.0.1:${PIGA_PORT:-8087}"
echo "Usuario: admin  |  Contraseña: changeme"
echo "Cambia la contraseña en: http://127.0.0.1:${PIGA_PORT:-8087}/app/useradministration"
echo ""
echo "Docat listo en http://127.0.0.1:${DOCAT_PORT:-8089}"
