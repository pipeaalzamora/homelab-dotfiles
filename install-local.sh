#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Instalación local en computador personal
# No instala paquetes, no toca SSH, UFW ni Tailscale.
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/env/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No se encontró env/.env"
  echo "Copia la plantilla primero:"
  echo "  cp env/.env.example env/.env"
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

HOMELAB_ROOT=${HOMELAB_ROOT:-/home/pipeaalzamora/homelab}
export HOMELAB_ROOT

compose_up() {
  local stack="$1"
  docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/$stack/docker-compose.yml" up -d
}

prepare_local() {
  echo "Creando estructura local en $HOMELAB_ROOT"
  PUID=${PUID:-1000} PGID=${PGID:-1000} HOMELAB_ROOT="$HOMELAB_ROOT" bash "$SCRIPT_DIR/scripts/03-dirs.sh"
  docker network create homelab 2>/dev/null || true
  copy_configs
}

copy_configs() {
  mkdir -p "$HOMELAB_ROOT/homelab/personal"
  cp "$SCRIPT_DIR/stacks/personal/nextcloud-nginx.conf" "$HOMELAB_ROOT/homelab/personal/nextcloud-nginx.conf"

  mkdir -p "$HOMELAB_ROOT/data/homepage/config"
  cp "$SCRIPT_DIR/configs/homepage/"*.yaml "$HOMELAB_ROOT/data/homepage/config/"
}

echo ""
echo "Homelab local en: $HOMELAB_ROOT"
echo ""
echo "  1) Preparar carpetas + core"
echo "  2) Multimedia"
echo "  3) Cloud local"
echo "  4) Proyectos y wiki"
echo "  5) Backups"
echo "  6) Opcional: n8n"
echo "  a) Ruta recomendada local (1-4)"
echo ""
read -rp "Opción [1-6/a]: " OPCION

case "$OPCION" in
  1)
    prepare_local
    compose_up core
    ;;
  2)
    compose_up media
    ;;
  3)
    copy_configs
    compose_up personal
    ;;
  4)
    compose_up dev
    ;;
  5)
    compose_up backups
    ;;
  6)
    compose_up tools
    ;;
  a|A)
    prepare_local
    compose_up core
    compose_up media
    compose_up personal
    compose_up dev
    ;;
  *)
    echo "Opción no válida."
    exit 1
    ;;
esac

echo ""
echo "Instalación local completada."
