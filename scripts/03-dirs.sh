#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Estructura de directorios /srv
# Crea todos los mount points antes de levantar los stacks
# =============================================================
set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "========================================="
echo " [03] Estructura de directorios /srv"
echo "========================================="

# --- Raíces principales ---------------------------------------
mkdir -p /srv/{homelab,data,media,cloud,backups}

# --- /srv/homelab — docker-compose.yml y configs --------------
mkdir -p /srv/homelab/{core,personal,media,dev,tools,backups,smarthome,security}

# --- /srv/data — datos persistentes por servicio --------------
# Core
mkdir -p /srv/data/{portainer,npm/{data,letsencrypt},adguard/{work,conf},homepage/config,uptime-kuma}

# Personal
mkdir -p /srv/data/nextcloud/{html,db}
mkdir -p /srv/cloud/nextcloud-data

# Media
mkdir -p /srv/data/{jellyfin/{config,cache},jellyseerr/config,sonarr/config,radarr/config,prowlarr/config,bazarr/config,qbittorrent/config}

# Dev
mkdir -p /srv/data/{forgejo/{data,db},bookstack/{data,db}}

# Tools
mkdir -p /srv/data/n8n/{app,db}

# Smarthome
mkdir -p /srv/data/{homeassistant/config,ollama/models,openwebui}

# Security
mkdir -p /srv/data/authelia/{config,redis}

# --- /srv/media — estructura multimedia -----------------------
mkdir -p /srv/media/{movies,series,music,downloads/{complete,incomplete,watch}}

# --- /srv/backups — backups locales ---------------------------
mkdir -p /srv/backups/{db,compose,exports,restic-repo}

# --- Permisos -------------------------------------------------
chown -R "${PUID}:${PGID}" /srv/homelab
chown -R "${PUID}:${PGID}" /srv/data
chown -R "${PUID}:${PGID}" /srv/media
chown -R "${PUID}:${PGID}" /srv/cloud
chown -R "${PUID}:${PGID}" /srv/backups

echo ""
echo "📁  Estructura creada:"
find /srv -maxdepth 2 -type d | sort

echo ""
echo "✅  Directorios listos."
echo "   Próximo paso: bash scripts/04-tailscale.sh"
