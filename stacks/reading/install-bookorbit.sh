#!/bin/bash
set -e

echo "📚 Instalando BookOrbit..."

# Crear directorio de datos
mkdir -p "${HOMELAB_ROOT}/data/reading/bookorbit"

# Iniciar servicio
cd "${HOMELAB_ROOT}/homelab-dotfiles/stacks/reading"
docker compose up -d

echo "✅ BookOrbit instalado y corriendo en http://${LAN_IP}:8090"
echo ""
echo "Credenciales por defecto (cambiar en la UI):"
echo "  Usuario: admin@homelab.local"
echo "  Contraria: admin123"
