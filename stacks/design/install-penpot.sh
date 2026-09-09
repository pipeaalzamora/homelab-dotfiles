#!/bin/bash
set -e

echo "🎨 Instalando Penpot..."

# Crear directorios de datos
mkdir -p "${HOMELAB_ROOT}/data/design/penpot-postgres"
mkdir -p "${HOMELAB_ROOT}/data/design/penpot-assets"

# Generar secret key aleatorio si no existe
if [ ! -f "${HOMELAB_ROOT}/homelab-dotfiles/env/.penpot-secret" ]; then
  openssl rand -hex 32 > "${HOMELAB_ROOT}/homelab-dotfiles/env/.penpot-secret"
  echo "🔑 Secret key generada y guardada"
fi

PENPOT_SECRET=$(cat "${HOMELAB_ROOT}/homelab-dotfiles/env/.penpot-secret")
export PENPOT_SECRET

# Iniciar servicios
cd "${HOMELAB_ROOT}/homelab-dotfiles/stacks/design"
docker compose up -d

echo "✅ Penpot instalado y corriendo en http://${LAN_IP}:8091"
echo ""
echo "Primer registro habilita la cuenta de administrador."
echo "Recomendado: usar correo corporativo y contraseña fuerte."
