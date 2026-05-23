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

# --- Menú de selección ----------------------------------------
echo "Selecciona el día de instalación:"
echo ""
echo "  1) Día 1 — Base del sistema (scripts base + stack core)"
echo "  2) Día 2 — Nube personal (stack personal)"
echo "  3) Día 3 — Media (stack media)"
echo "  4) Día 4 — Dev y startup (stack dev)"
echo "  5) Día 5 — Automatización + IA (stacks tools + smarthome)"
echo "  6) Día 6 — Seguridad (stack security)"
echo "  a) Todo en orden (días 1-6)"
echo ""
read -rp "Opción [1-6/a]: " OPCION

run_day1() {
  echo ""
  echo "━━━ DÍA 1: Sistema base ━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/scripts/01-base.sh"
  bash "$SCRIPT_DIR/scripts/02-docker.sh"
  bash "$SCRIPT_DIR/scripts/03-dirs.sh"
  bash "$SCRIPT_DIR/scripts/04-tailscale.sh"
  copy_env_to_stacks
  echo ""
  echo "Levantando stack core..."
  docker compose -f "$SCRIPT_DIR/stacks/core/docker-compose.yml" up -d
  echo "✅  Día 1 completado."
}

run_day2() {
  echo ""
  echo "━━━ DÍA 2: Nube personal ━━━━━━━━━━━━━━━━━━━━━"
  copy_configs_personal
  docker compose -f "$SCRIPT_DIR/stacks/personal/docker-compose.yml" up -d
  echo "✅  Día 2 completado."
}

run_day3() {
  echo ""
  echo "━━━ DÍA 3: Media ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  docker compose -f "$SCRIPT_DIR/stacks/media/docker-compose.yml" up -d
  echo "✅  Día 3 completado."
}

run_day4() {
  echo ""
  echo "━━━ DÍA 4: Dev y startup ━━━━━━━━━━━━━━━━━━━━━"
  docker compose -f "$SCRIPT_DIR/stacks/dev/docker-compose.yml" up -d
  echo "✅  Día 4 completado."
}

run_day5() {
  echo ""
  echo "━━━ DÍA 5: Automatización + IA ━━━━━━━━━━━━━━━"
  copy_configs_homepage
  docker compose -f "$SCRIPT_DIR/stacks/tools/docker-compose.yml" up -d
  docker compose -f "$SCRIPT_DIR/stacks/smarthome/docker-compose.yml" up -d
  pull_ollama_models
  echo "✅  Día 5 completado."
}

run_day6() {
  echo ""
  echo "━━━ DÍA 6: Seguridad ━━━━━━━━━━━━━━━━━━━━━━━━━"
  copy_configs_authelia
  docker compose -f "$SCRIPT_DIR/stacks/security/docker-compose.yml" up -d
  echo ""
  echo "⚠️  Authelia requiere configuración manual:"
  echo "   1. Editar /srv/data/authelia/config/configuration.yml"
  echo "   2. Generar hash de contraseña:"
  echo "      docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'TU_PASS'"
  echo "   3. Pegar hash en /srv/data/authelia/config/users_database.yml"
  echo "   4. docker compose -f stacks/security/docker-compose.yml restart authelia"
  echo "✅  Día 6 completado."
}

copy_env_to_stacks() {
  for stack_dir in "$SCRIPT_DIR/stacks"/*/; do
    if [[ -f "$stack_dir/docker-compose.yml" ]]; then
      cp "$ENV_FILE" "$stack_dir/.env"
    fi
  done
  echo "[.env] Copiado a todos los stacks."
}

copy_configs_personal() {
  cp "$SCRIPT_DIR/stacks/personal/nextcloud-nginx.conf" /srv/homelab/personal/nextcloud-nginx.conf
  echo "[Config] nextcloud-nginx.conf copiado."
}

copy_configs_homepage() {
  mkdir -p /srv/data/homepage/config
  cp "$SCRIPT_DIR/configs/homepage/"*.yaml /srv/data/homepage/config/
  echo "[Config] Homepage configs copiados."
}

copy_configs_authelia() {
  mkdir -p /srv/data/authelia/config
  cp "$SCRIPT_DIR/configs/authelia/configuration.yml" /srv/data/authelia/config/configuration.yml
  cp "$SCRIPT_DIR/configs/authelia/users_database.yml" /srv/data/authelia/config/users_database.yml
  echo "[Config] Authelia configs copiados."
  echo "⚠️  Editar /srv/data/authelia/config/configuration.yml con tus valores reales."
}

pull_ollama_models() {
  echo "Descargando modelos Ollama recomendados para Ryzen 5 5500 + 32 GB RAM..."
  echo "(Puede tardar varios minutos según la conexión)"
  # Esperar a que Ollama arranque
  sleep 10
  docker exec -it ollama ollama pull mistral:7b   || true
  docker exec -it ollama ollama pull gemma3:4b    || true
  echo "[Ollama] Modelos descargados."
}

case "$OPCION" in
  1) run_day1 ;;
  2) run_day2 ;;
  3) run_day3 ;;
  4) run_day4 ;;
  5) run_day5 ;;
  6) run_day6 ;;
  a|A)
    run_day1
    run_day2
    run_day3
    run_day4
    run_day5
    run_day6
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
