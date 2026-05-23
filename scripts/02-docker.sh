#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Día 1: Docker CE + Docker Compose
# =============================================================
set -euo pipefail

echo "========================================="
echo " [02] Docker CE + Docker Compose plugin"
echo "========================================="

# Eliminar versiones antiguas si existen
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

# Instalar dependencias
apt-get update -y
apt-get install -y ca-certificates curl gnupg

# Agregar clave GPG oficial de Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Añadir usuario pipe al grupo docker
usermod -aG docker pipe

# Habilitar y arrancar Docker
systemctl enable docker
systemctl start docker

# Verificar
docker --version
docker compose version

# --- Red Docker global del homelab ----------------------------
# Todos los stacks usan esta red para comunicarse entre sí
docker network create homelab 2>/dev/null || echo "[Red] homelab ya existe."

echo ""
echo "✅  Docker instalado."
echo "   Red 'homelab' creada."
echo "   Cierra sesión y vuelve a entrar para usar docker sin sudo."
echo "   Próximo paso: bash scripts/03-dirs.sh"
