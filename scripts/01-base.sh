#!/usr/bin/env bash
# =============================================================
# Homelab Pipe Edition — Día 1: Sistema base
# Ubuntu Server 24.04 LTS
# Configura: usuario pipe, SSH hardening, UFW, actualizaciones
# =============================================================
set -euo pipefail

echo "========================================="
echo " [01] Sistema base — Ubuntu Server"
echo "========================================="

# --- Actualización del sistema --------------------------------
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  curl wget git vim htop unzip \
  net-tools dnsutils \
  ca-certificates gnupg lsb-release \
  ufw fail2ban \
  unattended-upgrades apt-listchanges

# --- Crear usuario pipe si no existe --------------------------
if ! id "pipe" &>/dev/null; then
  useradd -m -s /bin/bash -G sudo pipe
  echo "Usuario 'pipe' creado. Asignar contraseña:"
  passwd pipe
fi

# --- Configurar actualizaciones automáticas ------------------
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# --- SSH hardening --------------------------------------------
SSH_CONFIG=/etc/ssh/sshd_config

# Hacer backup del config original
cp "$SSH_CONFIG" "${SSH_CONFIG}.bak.$(date +%Y%m%d)"

# Aplicar configuración segura
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"

# Agregar opciones si no existen
grep -q "^AllowUsers" "$SSH_CONFIG" || echo "AllowUsers pipe" >> "$SSH_CONFIG"
grep -q "^MaxAuthTries" "$SSH_CONFIG" || echo "MaxAuthTries 3" >> "$SSH_CONFIG"
grep -q "^ClientAliveInterval" "$SSH_CONFIG" || echo "ClientAliveInterval 300" >> "$SSH_CONFIG"
grep -q "^ClientAliveCountMax" "$SSH_CONFIG" || echo "ClientAliveCountMax 2" >> "$SSH_CONFIG"

systemctl restart sshd
echo "[SSH] Configuración aplicada."

# --- UFW (Firewall) -------------------------------------------
# CRÍTICO: habilitar SSH antes de activar UFW
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp comment 'SSH'

# HTTP/HTTPS para Nginx Proxy Manager
ufw allow 80/tcp comment 'HTTP NPM'
ufw allow 443/tcp comment 'HTTPS NPM'

# Tailscale (UDP)
ufw allow 41641/udp comment 'Tailscale'

# AdGuard DNS (solo red local — ajustar si necesitas)
# ufw allow from 192.168.1.0/24 to any port 53

# Activar UFW
ufw --force enable
echo "[UFW] Firewall activado."
ufw status verbose

# --- Fail2ban -------------------------------------------------
systemctl enable fail2ban
systemctl start fail2ban
echo "[Fail2ban] Activo."

# --- Hostname -------------------------------------------------
hostnamectl set-hostname homelab-pipe
echo "[Hostname] homelab-pipe configurado."

# --- Timezone -------------------------------------------------
timedatectl set-timezone America/Santiago
echo "[Timezone] America/Santiago."

echo ""
echo "✅  Sistema base configurado."
echo "   Próximo paso: bash scripts/02-docker.sh"
