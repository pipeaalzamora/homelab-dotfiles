#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Estructura de directorios
# Crea todos los mount points antes de levantar los stacks
# =============================================================
set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}
HOMELAB_ROOT=${HOMELAB_ROOT:-/srv}

echo "========================================="
echo " [03] Estructura de directorios"
echo "========================================="
echo "Root: $HOMELAB_ROOT"

# --- Raíces principales ---------------------------------------
mkdir -p "$HOMELAB_ROOT"/{homelab,data,media,cloud,backups}

# --- homelab — docker-compose.yml y configs -------------------
mkdir -p "$HOMELAB_ROOT"/homelab/{core,personal,media,dev,tools,backups,smarthome,security,secrets}

# --- data — datos persistentes por servicio --------------------
# Core
mkdir -p "$HOMELAB_ROOT"/data/{portainer,npm/{data,letsencrypt},adguard/{work,conf},homepage/config,uptime-kuma}

# Personal
mkdir -p "$HOMELAB_ROOT"/data/nextcloud/{html,db}
mkdir -p "$HOMELAB_ROOT"/cloud/nextcloud-data

# Media
mkdir -p "$HOMELAB_ROOT"/data/{jellyfin/{config,cache},jellyseerr/config,sonarr/config,radarr/config,prowlarr/config,bazarr/config,qbittorrent/config}

# Dev
mkdir -p "$HOMELAB_ROOT"/data/{forgejo/{data,db},bookstack/{data,db}}

# Tools
mkdir -p "$HOMELAB_ROOT"/data/n8n/{app,db}

# Secrets (Infisical)
mkdir -p "$HOMELAB_ROOT"/data/infisical/{db,redis}

# Smarthome
mkdir -p "$HOMELAB_ROOT"/data/{homeassistant/config,ollama/models,openwebui}

# Security
mkdir -p "$HOMELAB_ROOT"/data/authelia/{config,redis}

# --- media — estructura multimedia ----------------------------
mkdir -p "$HOMELAB_ROOT"/media/{movies,series,music,downloads/{complete,incomplete,watch}}

# --- backups — backups locales --------------------------------
mkdir -p "$HOMELAB_ROOT"/backups/{db,compose,exports,restic-repo}

# --- Permisos -------------------------------------------------
chown -R "${PUID}:${PGID}" "$HOMELAB_ROOT"/homelab
chown -R "${PUID}:${PGID}" "$HOMELAB_ROOT"/data
chown -R "${PUID}:${PGID}" "$HOMELAB_ROOT"/media
chown -R "${PUID}:${PGID}" "$HOMELAB_ROOT"/cloud
chown -R "${PUID}:${PGID}" "$HOMELAB_ROOT"/backups

echo ""
echo "📁  Estructura creada:"
find "$HOMELAB_ROOT" -maxdepth 2 -type d | sort

echo ""
echo "✅  Directorios listos."
echo "   Próximo paso: bash scripts/04-tailscale.sh"
