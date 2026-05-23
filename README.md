# 🖥️ Homelab — Pipe Edition · Dotfiles

Dotfiles y scripts de despliegue para el homelab personal.  
Ubuntu Server · Docker Compose · Tailscale · Nginx Proxy Manager · Authelia

## Estructura

```
dotfiles/
├── README.md
├── install.sh                  # Script maestro — corre todo en orden
├── scripts/
│   ├── 01-base.sh              # Ubuntu base, usuario pipe, SSH hardening, UFW
│   ├── 02-docker.sh            # Docker CE + Docker Compose plugin
│   ├── 03-dirs.sh              # Estructura de directorios /srv
│   └── 04-tailscale.sh         # Instalación Tailscale
├── stacks/
│   ├── core/                   # Portainer, NPM, AdGuard, Netdata
│   ├── personal/               # Nextcloud+OnlyOffice, Immich, Vaultwarden, Paperless
│   ├── media/                  # Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Transmission
│   ├── dev/                    # Forgejo, Woodpecker CI, BookStack, Actual Budget
│   ├── tools/                  # n8n, Homepage, Uptime Kuma, Restic
│   ├── smarthome/              # Home Assistant, Ollama, Open WebUI
│   └── security/               # Authelia + Redis
├── configs/
│   ├── authelia/               # configuration.yml, users_database.yml
│   └── homepage/               # settings.yaml, services.yaml, widgets.yaml
└── env/
    └── .env.example            # Plantilla de variables — copiar a .env y editar
```

## Uso rápido

```bash
git clone https://github.com/tuusuario/homelab-dotfiles ~/dotfiles
cd ~/dotfiles
cp env/.env.example env/.env
nano env/.env          # Rellenar tus valores reales
chmod +x install.sh
sudo ./install.sh
```

## Orden de despliegue

| Día | Stack | Resultado |
|-----|-------|-----------|
| 1 | `scripts/` + `stacks/core/` | Sistema base seguro |
| 2 | `stacks/personal/` | Nube personal |
| 3 | `stacks/media/` | Streaming automático |
| 4 | `stacks/dev/` | Dev y startup |
| 5 | `stacks/tools/` + `stacks/smarthome/` | Automatización e IA |
| 6 | `stacks/security/` + Restic | Producción |

## Red interna

Todos los contenedores usan la red Docker `homelab`.  
Solo Nginx Proxy Manager expone los puertos 80/443 al exterior.  
El resto de servicios son accesibles únicamente por Tailscale o a través del proxy.
