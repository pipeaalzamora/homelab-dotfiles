#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
HOMEPAGE_PORT="${HOMEPAGE_PORT:-3000}"

info() { printf '\n==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

preflight() {
  info "Comprobando requisitos"
  [[ "$(uname -s)" == "Linux" ]] || fail "Usa install-windows.ps1 en Windows."
  command_exists docker || fail "Docker no está instalado. Instálalo y vuelve a ejecutar el script."
  docker info >/dev/null 2>&1 || fail "El daemon de Docker no está disponible. Inicia Docker y verifica permisos con: docker info"
  docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 no está disponible."
  command_exists python3 || fail "Python 3 no está instalado."
  python3 - <<'PY' || fail "Se requiere Python 3.8 o superior."
import sys
raise SystemExit(0 if sys.version_info >= (3, 8) else 1)
PY
  command_exists openssl || fail "openssl no está instalado; se usa para generar secretos seguros."
  command_exists awk || fail "awk no está instalado."
  [[ -d "$ROOT_DIR/stacks" ]] || fail "No se encontró el directorio stacks/."
}

generate_secret() { openssl rand -base64 48 | tr -d '\n' | tr '/+' '_-' | cut -c1-48; }

generate_env() {
  local template="$ROOT_DIR/env/.env.example"
  [[ -f "$template" ]] || { info "No hay env/.env.example; se omite .env"; return; }
  if [[ -f "$ENV_FILE" ]]; then
    info "Se conserva .env existente"
    return
  fi
  info "Generando .env con secretos aleatorios"
  : > "$ENV_FILE"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]] || [[ "$line" != *=* ]]; then printf '%s\n' "$line" >> "$ENV_FILE"; continue; fi
    key="${line%%=*}"; value="${line#*=}"
    if [[ "$key" =~ (SECRET|PASSWORD|PASS|TOKEN|KEY|JWT|SALT) ]] && { [[ -z "$value" ]] || [[ "$value" =~ ^(CHANGE_ME|CHANGEME|REPLACE_ME|example|your_.*)$ ]]; }; then
      value="$(generate_secret)"
    fi
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  done < "$template"
  chmod 600 "$ENV_FILE"
}

compose_files() { find "$ROOT_DIR/stacks" -type f \( -name 'compose.yml' -o -name 'compose.yaml' -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \) -print | sort; }

install_stack() {
  local file dir count=0
  while IFS= read -r file; do
    dir="$(dirname "$file")"
    info "Validando ${file#$ROOT_DIR/}"
    (cd "$dir" && docker compose --env-file "$ENV_FILE" -f "$file" config -q)
    info "Iniciando ${file#$ROOT_DIR/}"
    (cd "$dir" && docker compose --env-file "$ENV_FILE" -f "$file" up -d)
    ((count+=1))
  done < <(compose_files)
  (( count > 0 )) || fail "No se encontraron archivos Docker Compose en stacks/."
}

local_ip() { hostname -I 2>/dev/null | awk '{print $1}' || true; }

report() {
  local ip port
  ip="$(local_ip)"
  port="$(docker ps --format '{{.Names}} {{.Ports}}' | awk '/homepage/ { if (match($0, /0.0.0.0:([0-9]+)/, a)) print a[1] }' | head -n1)"
  port="${port:-$HOMEPAGE_PORT}"
  info "Estado de los contenedores"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  printf '\nHomepage: http://%s:%s\n' "${ip:-localhost}" "$port"
  printf 'Local:    http://localhost:%s\n' "$port"
  printf 'Configuración: %s\nVariables y secretos: %s\n' "$ROOT_DIR/configs" "$ENV_FILE"
}

preflight
generate_env
install_stack
report
