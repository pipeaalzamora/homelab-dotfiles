#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Script maestro de instalación
# Ejecutar como root desde el servidor: sudo bash install.sh
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/env/.env"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🖥️  Homelab — Pipe Edition                ║"
echo "║   Script de instalación automatizado        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# --- Verificar que se ejecuta como root -----------------------
if [[ $EUID -ne 0 ]]; then
  echo "❌  Este script debe ejecutarse como root: sudo bash install.sh"
  exit 1
fi

# --- Verificar que existe el .env -----------------------------
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌  No se encontró env/.env"
  echo "    Copia la plantilla y edítala primero:"
  echo "    cp env/.env.example env/.env && nano env/.env"
  exit 1
fi

# Cargar variables de entorno
# shellcheck source=/dev/null
source "$ENV_FILE"
HOMELAB_ROOT=${HOMELAB_ROOT:-/srv}

# --- Menú de selección ----------------------------------------
echo "Selecciona el día de instalación:"
echo ""
echo "  1) Base local (scripts base + core)"
echo "  2) Multimedia familiar (Jellyfin + arr + qBittorrent)"
echo "  3) Cloud local (Nextcloud)"
echo "  4) Proyectos y wiki local (Forgejo + BookStack)"
echo "  5) Backups (Restic)"
echo "  6) Opcional: automatización (n8n)"
echo "  7) Opcional: gestión de secretos (Infisical)"
echo "  8) Opcional: productividad (Excalidraw + Stirling-PDF)"
echo "  9) Opcional: finanzas (Facto)"
echo "  10) Opcional: conocimiento y docs (Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana)"
echo "  11) Opcional: seguridad SSO (Authelia)"
echo "  a) Ruta recomendada (1-5)"
echo ""
read -rp "Opción [1-11/a]: " OPCION

compose_up() {
  local stack="$1"
  docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/stacks/$stack/docker-compose.yml" up -d
}

run_core() {
  echo ""
  echo "━━━ BASE LOCAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/scripts/01-base.sh"
  bash "$SCRIPT_DIR/scripts/02-docker.sh"
  bash "$SCRIPT_DIR/scripts/03-dirs.sh"
  bash "$SCRIPT_DIR/scripts/04-tailscale.sh"
  copy_configs_homepage
  echo ""
  echo "Levantando stack core..."
  compose_up core
  echo "✅  Base local completada."
}

run_media() {
  echo ""
  echo "━━━ MULTIMEDIA ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  compose_up media
  echo "✅  Multimedia completado."
}

run_cloud() {
  echo ""
  echo "━━━ CLOUD LOCAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  copy_configs_personal
  compose_up personal
  echo "✅  Cloud local completado."
}

run_dev() {
  echo ""
  echo "━━━ PROYECTOS Y WIKI ━━━━━━━━━━━━━━━━━━━━━━━━━"
  compose_up dev
  echo "✅  Proyectos y wiki completado."
}

run_backups() {
  echo ""
  echo "━━━ BACKUPS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  compose_up backups
  echo "✅  Backups completado."
}

run_tools() {
  echo ""
  echo "━━━ OPCIONAL: N8N ━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  compose_up tools
  echo "✅  n8n completado."
}

run_secrets() {
  echo ""
  echo "━━━ OPCIONAL: INFISICAL ━━━━━━━━━━━━━━━━━━━━━━"
  compose_up secrets
  echo "✅  Infisical completado."
}

run_productivity() {
  echo ""
  echo "━━━ OPCIONAL: PRODUCTIVIDAD ━━━━━━━━━━━━━━━━━━"
  compose_up productivity
  echo "✅  Excalidraw + Stirling-PDF completado."
}

run_finance() {
  echo ""
  echo "━━━ OPCIONAL: FINANZAS ━━━━━━━━━━━━━━━━━━━━━━━"
  copy_configs_finance
  if [[ -d "$HOMELAB_ROOT/data/facto/db/mysql" ]]; then
    compose_up finance
  else
    bash "$SCRIPT_DIR/stacks/finance/init-facto.sh"
  fi
  echo "✅  Facto completado."
}

run_knowledge() {
  echo ""
  echo "━━━ OPCIONAL: CONOCIMIENTO Y DOCS ━━━━━━━━━━━━"
  copy_configs_knowledge
  if [[ -d "$HOMELAB_ROOT/data/piga/db/mysql" ]]; then
    compose_up knowledge
  else
    bash "$SCRIPT_DIR/stacks/knowledge/init-piga.sh"
  fi
  echo "✅  Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana completado."
}

run_security() {
  echo ""
  echo "━━━ OPCIONAL: SEGURIDAD SSO ━━━━━━━━━━━━━━━━━━"
  copy_configs_authelia
  compose_up security
  echo "✅  Authelia completado."
}

copy_configs_personal() {
  mkdir -p "$HOMELAB_ROOT/homelab/personal"
  cp "$SCRIPT_DIR/stacks/personal/nextcloud-nginx.conf" "$HOMELAB_ROOT/homelab/personal/nextcloud-nginx.conf"
  echo "[Config] nextcloud-nginx.conf copiado."
}

copy_configs_homepage() {
  mkdir -p "$HOMELAB_ROOT/data/homepage/config"
  cp "$SCRIPT_DIR/configs/homepage/"*.yaml "$HOMELAB_ROOT/data/homepage/config/"
  echo "[Config] Homepage configs copiados."
}

copy_configs_finance() {
  mkdir -p "$HOMELAB_ROOT/data/facto/config"
  if [[ ! -f "$HOMELAB_ROOT/data/facto/config/accounting-config.yml" ]]; then
    cp "$SCRIPT_DIR/configs/facto/accounting-config.yml" "$HOMELAB_ROOT/data/facto/config/accounting-config.yml"
    echo "[Config] Facto CLP copiado."
  else
    echo "[Config] Facto CLP existente preservado."
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

case "$OPCION" in
  1) run_core ;;
  2) run_media ;;
  3) run_cloud ;;
  4) run_dev ;;
  5) run_backups ;;
  6) run_tools ;;
  7) run_secrets ;;
  8) run_productivity ;;
  9) run_finance ;;
  10) run_knowledge ;;
  11) run_security ;;
  a|A)
    run_core
    run_media
    run_cloud
    run_dev
    run_backups
    ;;
  *)
    echo "Opción no válida."
    exit 1
    ;;
esac

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Instalación completada 🎉                 ║"
echo "║   Revisa los logs: docker compose logs -f   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
