#!/bin/bash
set -e

echo "💰 Instalando Securo (gestor de finanzas personales)..."

# Crear directorios de datos
mkdir -p "${HOMELAB_ROOT}/data/finance/securo-postgres"
mkdir -p "${HOMELAB_ROOT}/data/finance/securo-redis"
mkdir -p "${HOMELAB_ROOT}/data/finance/securo-attachments"

# Generar secret key aleatorio si no existe
if [ ! -f "${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-secret" ]; then
  openssl rand -hex 32 > "${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-secret"
  echo "🔑 Secret key generada y guardada"
fi

# Generar contraseña de base de datos si no existe
if [ ! -f "${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-db-pass" ]; then
  openssl rand -base64 24 > "${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-db-pass"
  echo "🔐 Contraseñ±±±a de base de datos generada y guardada"
fi

echo ""
echo "⚠️ IMPORTANTE: Editar stacks/finance/docker-compose.yml con:"
echo "  1. SECRET_KEY: $(cat ${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-secret)"
echo "  2. POSTGRES_PASSWORD: $(cat ${HOMELAB_ROOT}/homelab-dotfiles/env/.securo-db-pass)"
echo ""
echo "Luego ejecutar:"
echo "  cd stacks/finance && docker compose up -d"
echo ""
echo "✅ Securo estará disponible en http://${LAN_IP}:8092"
echo ""
echo "📖 Documentació±±±n: https://docs.usesecuro.com/"
echo "🔗 GitHub: https://github.com/securo-finance/securo"
