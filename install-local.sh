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
echo "  7) Opcional: Infisical (secretos)"
echo "  8) Opcional: Productividad (Excalidraw + Stirling-PDF)"
echo "  9) Opcional: Finanzas (Facto)"
echo "  10) Opcional: Conocimiento y docs (Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana)"
echo "  11) Opcional: Seguridad SSO (Authelia)"
echo "  a) Ruta recomendada local (1-4)"
echo ""
read -rp "Opción [1-11/a]: " OPCION

copy_configs_finance() {
  mkdir -p "$HOMELAB_ROOT/data/facto/config"
  if [[ ! -f "$HOMELAB_ROOT/data/facto/config/accounting-config.yml" ]]; then
    cp "$SCRIPT_DIR/configs/facto/accounting-config.yml" "$HOMELAB_ROOT/data/facto/config/accounting-config.yml"
    echo "[Config] Facto CLP copiado."
  else
    echo "[Config] Facto CLP existente preservado."
  fi
}

run_finance() {
  copy_configs_finance
  if [[ -d "$HOMELAB_ROOT/data/facto/db/mysql" ]]; then
    compose_up finance
  else
    bash "$SCRIPT_DIR/stacks/finance/init-facto.sh"
  fi
}

run_knowledge() {
  copy_configs_knowledge
  if [[ -d "$HOMELAB_ROOT/data/piga/db/mysql" ]]; then
    compose_up knowledge
  else
    bash "$SCRIPT_DIR/stacks/knowledge/init-piga.sh"
  fi
}

copy_configs_knowledge() {
  mkdir -p "$HOMELAB_ROOT/data/piga/db" "$HOMELAB_ROOT/data/docat" "$HOMELAB_ROOT/data/everydocs/config" "$HOMELAB_ROOT/data/everydocs/db" "$HOMELAB_ROOT/data/everydocs/files" "$HOMELAB_ROOT/data/dailytxt" "$HOMELAB_ROOT/data/wastebin" "$HOMELAB_ROOT/data/iguana"
  cp "$SCRIPT_DIR/configs/everydocs/everydocs-web-config.js" "$HOMELAB_ROOT/data/everydocs/config/everydocs-web-config.js"
  echo "[Config] EveryDocs Web copiado."
}

copy_configs_authelia() {
  mkdir -p "$HOMELAB_ROOT/data/authelia/config"
  cp "$SCRIPT_DIR/configs/authelia/configuration.yml" "$HOMELAB_ROOT/data/authelia/config/configuration.yml"
  if [[ ! -f "$HOMELAB_ROOT/data/authelia/config/users_database.yml" ]]; then
    cp "$SCRIPT_DIR/configs/authelia/users_database.yml" "$HOMELAB_ROOT/data/authelia/config/users_database.yml"
    echo "[Config] Authelia users_database.yml copiado."
  else
    echo "[Config] Authelia users_database.yml existente preservado."
  fi
}

run_security() {
  copy_configs_authelia
  compose_up security
}

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
  7)
    compose_up secrets
    ;;
  8)
    compose_up productivity
    ;;
  9)
    run_finance
    ;;
  10)
    run_knowledge
    ;;
  11)
    run_security
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
