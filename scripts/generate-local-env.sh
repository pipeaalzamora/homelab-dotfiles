#!/usr/bin/env bash
# =============================================================
# Genera env/.env para pruebas locales.
# No imprime secretos en pantalla.
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/env/.env"

if [[ -f "$ENV_FILE" ]]; then
  echo "env/.env ya existe. No se sobreescribe."
  exit 0
fi

rand_hex() {
  openssl rand -hex "$1"
}

rand_b64() {
  openssl rand -base64 "$1" | tr -d '\n'
}

cat > "$ENV_FILE" <<EOF
TZ=America/Santiago
PUID=1000
PGID=1000
HOMELAB_ROOT=/home/pipeaalzamora/homelab
LOCAL_DOMAIN=home
NPM_HTTP_PORT=8088
NPM_HTTPS_PORT=8443
NPM_ADMIN_PORT=8181
ADGUARD_DNS_PORT=1053
ADGUARD_SETUP_PORT=3000
ADGUARD_ADMIN_PORT=8080
HOMEPAGE_ALLOWED_HOSTS=localhost:3001,127.0.0.1:3001
ADGUARD_USERNAME=pipe
ADGUARD_PASSWORD=$(rand_b64 24)

TAILSCALE_AUTHKEY=

NEXTCLOUD_ADMIN_USER=pipe
NEXTCLOUD_ADMIN_PASSWORD=$(rand_b64 24)
NEXTCLOUD_DB_ROOT_PASSWORD=$(rand_b64 24)
NEXTCLOUD_DB_PASSWORD=$(rand_b64 24)
NEXTCLOUD_TRUSTED_DOMAINS='cloud.home homelab-pipe localhost'

QBITTORRENT_USERNAME=admin
QBITTORRENT_PASSWORD=$(rand_b64 18)

FORGEJO_DB_PASSWORD=$(rand_b64 24)
FORGEJO_DOMAIN=localhost
FORGEJO_ROOT_URL=http://localhost:3004/
FORGEJO_SSH_DOMAIN=localhost
FORGEJO_SECRET_KEY=$(rand_hex 32)
FORGEJO_INTERNAL_TOKEN=$(rand_hex 32)

BOOKSTACK_DB_PASSWORD=$(rand_b64 24)
BOOKSTACK_APP_KEY=base64:$(rand_b64 32)
BOOKSTACK_APP_URL=http://localhost:6875

N8N_DB_PASSWORD=$(rand_b64 24)
N8N_ENCRYPTION_KEY=$(rand_hex 24)
N8N_BASIC_AUTH_USER=pipe
N8N_BASIC_AUTH_PASSWORD=$(rand_b64 24)

RESTIC_REPOSITORY=/home/pipeaalzamora/homelab/backups/restic-repo
RESTIC_PASSWORD=$(rand_b64 32)
B2_ACCOUNT_ID=
B2_ACCOUNT_KEY=
EOF

chmod 600 "$ENV_FILE"
echo "env/.env generado."
