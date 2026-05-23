#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Tailscale
# VPN mesh — acceso remoto sin puertos expuestos
# =============================================================
set -euo pipefail

echo "========================================="
echo " [04] Tailscale"
echo "========================================="

# Instalar Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Habilitar IP forwarding (para usar como exit node / subnet router)
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf

# Habilitar y arrancar
systemctl enable tailscaled
systemctl start tailscaled

echo ""
echo "Para conectar el servidor a tu red Tailscale, ejecuta:"
echo ""
echo "  sudo tailscale up --advertise-exit-node --advertise-routes=192.168.1.0/24"
echo ""
echo "  O con authkey (sin interacción):"
echo "  sudo tailscale up --authkey=tskey-auth-XXXXX --advertise-exit-node"
echo ""
echo "  Verificar estado:"
echo "  tailscale status"
echo ""
echo "✅  Tailscale instalado."
echo "   Próximo paso: levantar stacks en stacks/core/"
