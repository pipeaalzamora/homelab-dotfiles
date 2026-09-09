# Homelab Dotfiles

Dotfiles y configuración para despliegue de homelab con Docker Compose. Diseñ±±±ado para ser multiplataforma (Linux, macOS, Windows).

## Estructura de Directorios

```
homelab-dotfiles/
├── configs/           # Configuraciones compartidas
├── env/               # Variables de entorno (.env.example)
├── stacks/            # Stacks de servicios Docker
│   ├── core/          # Servicios base
│   ├── media/         # Multimedia (Jellyfin, Sonarr, Radarr, etc.)
│   ├── productivity/  # Productividad (Excalidraw, Stirling-PDF, AppFlowy)
│   ├── secrets/       # Gestión de secretos (Infisical)
│   ├── reading/       # Lectura (BookOrbit)
│   ├── design/        # Diseño UI/UX (Penpot)
│   └── finance/       # Finanzas personales (Securo)
├── install.sh         # Script de instalación Linux/macOS
├── install.ps1        # Script de instalación Windows
└── install-local.sh   # Instalació±±±n local (desarrollo)
```

## Servicios por Stack

### Core (`stacks/core/`)
- Portainer (puertos 3000-3001)
- Docker Socket Proxy (interno, sin puerto expuesto)

### Media (`stacks/media/`)
- Jellyfin (3002)
- Sonarr (3003)
- Radarr (3004)
- Prowlarr (3005)
- Bazarr (3006)
- Transmission (3007)

### Productivity (`stacks/productivity/`)
- Excalidraw (3008)
- Stirling-PDF (3009)

### Productivity (`stacks/appflowy/`)
- AppFlowy HTTP (3015)
- AppFlowy HTTPS (3016)

### Secrets (`stacks/secrets/`)
- Infisical (3010)

### Reading (`stacks/reading/`)
- BookOrbit (3011)

### Design (`stacks/design/`)
- Penpot (3012)

### Finance (`stacks/finance/`)
- Securo Frontend (3013)
- Securo Backend API (3014)

## Acceso a Servicios

Todos los servicios están disponibles en `http://${LAN_IP}:${PUERTO}`:

| Servicio | Puerto | URL |
|----------|--------|-----|
| Portainer (API) | 3000 | `http://${LAN_IP}:3000` |
| Portainer (UI) | 3001 | `http://${LAN_IP}:3001` |
| Jellyfin | 3002 | `http://${LAN_IP}:3002` |
| Sonarr | 3003 | `http://${LAN_IP}:3003` |
| Radarr | 3004 | `http://${LAN_IP}:3004` |
| Prowlarr | 3005 | `http://${LAN_IP}:3005` |
| Bazarr | 3006 | `http://${LAN_IP}:3006` |
| Transmission | 3007 | `http://${LAN_IP}:3007` |
| Excalidraw | 3008 | `http://${LAN_IP}:3008` |
| Stirling-PDF | 3009 | `http://${LAN_IP}:3009` |
| Infisical | 3010 | `http://${LAN_IP}:3010` |
| BookOrbit | 3011 | `http://${LAN_IP}:3011` |
| Penpot | 3012 | `http://${LAN_IP}:3012` |
| Securo Frontend | 3013 | `http://${LAN_IP}:3013` |
| Securo Backend API | 3014 | `http://${LAN_IP}:3014` |
| AppFlowy HTTP | 3015 | `http://${LAN_IP}:3015` |
| AppFlowy HTTPS | 3016 | `http://${LAN_IP}:3016` |

## Instalació±±±n

### Linux/macOS

```bash
# Clonar repositorio
git clone https://github.com/pipeaalzamora/homelab-dotfiles.git
cd homelab-dotfiles

# Ejecutar instalador
chmod +x install.sh
./install.sh
```

### Windows

```powershell
# Clonar repositorio
git clone https://github.com/pipeaalzamora/homelab-dotfiles.git
cd homelab-dotfiles

# Ejecutar instalador
.\install.ps1
```

## Variables de Entorno

El archivo `env/.env.example` contiene las variables necesarias:

- `HOMELAB_ROOT`: Ruta base del homelab (ej. `/srv/homelab` o `C:\homelab`)
- `LAN_IP`: IP local del servidor (ej. `192.168.1.100`)
- `PUID`/`PGID`: IDs de usuario/grupo para permisos (Linux/macOS)

## Eliminados (Agosto 2026)

En la consolidació±±±n de agosto 2026 se eliminaron los siguientes servicios:
- Restic (backups)
- Nginx Proxy Manager
- AdGuard Home
- Netdata
- Authelia (SSO)
- Stacks completos: dev, finance (Facto), knowledge, personal, security

## Seguridad

- ⚠️ Cambiar todas las contraseñ±±±as por defecto
- ⚠️ Generar secret keys aleatorias para cada servicio
- ⚠️ No exponer puertos directamente a Internet sin reverse proxy + autenticació±±±n
- ⚠️ Usar red Docker externa (`homelab`) para aislar servicios

## Comandos Útiles

```bash
# Ver servicios corriendo
docker compose ps

# Ver logs de un servicio
docker compose logs -f <servicio>

# Reiniciar un stack
cd stacks/<stack>
docker compose restart

# Detener un stack
docker compose down
```

## Créditos

- [BookOrbit](https://github.com/bookorbit/bookorbit) - Plataforma de lectura self-hosted
- [Penpot](https://penpot.app/) - Plataforma de diseño UI/UX open-source
- [Securo](https://github.com/securo-finance/securo) - Gestor de finanzas personales self-hosted
- [AppFlowy](https://github.com/AppFlowyIO/AppFlowy-Cloud) - Notas self-hosted
- [Infisical](https://github.com/Infisical/infisical) - Gestió±±±n de secretos
- [Servers@Home](https://wiki.serversatho.me/) - Guí±± ±as de TrueNAS y Docker

---

**Autor:** Felipe "pipe" Aros Alzamora  
**Email:** pipeaalzamora@gmail.com  
**Ubicació±±±n:** Santiago, Chile  
**Ú± ±ltima actualizació±±±n:** Septiembre 2026
