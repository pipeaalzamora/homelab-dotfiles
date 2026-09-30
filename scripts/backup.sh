#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$ROOT/.env"; set +a
: "${HOMELAB_ROOT:?HOMELAB_ROOT no definido en .env}"

BACKUP_DIR="${BACKUP_DIR:-$HOMELAB_ROOT/backups}"
KEEP="${BACKUP_KEEP:-7}"
DEST="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"

dump_pg() {
  local container="$1" user="$2" db="$3"
  if docker ps --format '{{.Names}}' | grep -qx "$container"; then
    docker exec "$container" pg_dump -U "$user" "$db" | gzip > "$DEST/$container.sql.gz"
    echo "dump: $container"
  fi
}

dump_pg tandoor-db djangouser djangodb
dump_pg productivity-penpot-postgres-1 penpot penpot

for d in vaultwarden vikunja baserow tandoor/mediafiles penpot/assets; do
  if [ -d "$HOMELAB_ROOT/data/$d" ]; then
    if tar -czf "$DEST/$(echo "$d" | tr '/' '_').tar.gz" -C "$HOMELAB_ROOT/data" "$d"; then
      echo "tar: $d"
    else
      echo "aviso: no se pudo leer $d (permisos). Proba con sudo."
    fi
  fi
done

ls -1dt "$BACKUP_DIR"/*/ | tail -n +$((KEEP + 1)) | xargs -r rm -rf
echo "Backup listo en $DEST"
