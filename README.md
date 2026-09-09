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
│   ├── productivity/  # Productividad (Excalidraw, Stirling-PDF)
│   ├── appflowy/      # Notas (AppFlowy-Cloud)
│   ├── secrets/       # Gestión de secretos (Infisical)
│   ├── reading/       # Lectura (BookOrbit)
│   ├── design/        # Diseño UI/UX (Penpot)
│   └── finance/       # Finanzas personales (Securo) ⭐ NUEVO
├── install.sh         # Script de instalación Linux/macOS
├── install.ps1        # Script de instalación Windows
└── install-local.sh   # Instalació±±±n local (desarrollo)
```

## Servicios por Stack

### Core (`stacks/core/`)
- Portainer
- Docker Socket Proxy (para Homepage)

### Media (`stacks/media/`)
- Jellyfin (con aceleració±±±n GPU)
- Sonarr
- Radarr
- Prowlarr
- Bazarr
- Transmission

### Productivity (`stacks/productivity/`)
- Excalidraw (diagramas)
- Stirling-PDF (herramientas PDF)

### AppFlowy (`stacks/appflowy/`)
- AppFlowy-Cloud (notas self-hosted)

### Secrets (`stacks/secrets/`)
- Infisical (gestió±±±n centralizada de secretos con PostgreSQL + Redis)

### Reading (`stacks/reading/`)
- BookOrbit (biblioteca de ebooks, audiobooks, cómics y PDFs)

### Design (`stacks/design/`)
- Penpot (plataforma de diseño UI/UX open-source)

### Finance (`stacks/finance/`) ⭐ NUEVO
- Securo (gestor de finanzas personales con bank sync opcional, presupuestos, metas, inversiones)

## Acceso a Servicios

Todos los servicios están disponibles en `http://${LAN_IP}:${PUERTO}`:

| Servicio | Puerto | URL |
|----------|--------|-----|
| Portainer | 8081 | `http://${LAN_IP}:8081` |
| Jellyfin | 8096 | `http://${LAN_IP}:8096` |
| Excalidraw | 8084 | `http://${LAN_IP}:8084` |
| Stirling-PDF | 8085 | `http://${LAN_IP}:8085` |
| AppFlowy | 8095 | `http://${LAN_IP}:8095` |
| Infisical | 8087 | `http://${LAN_IP}:8087` |
| BookOrbit | 8090 | `http://${LAN_IP}:8090` |
| Penpot | 8091 | `http://${LAN_IP}:8091` |
| Securo | 8092 | `http://${LAN_IP}:8092` |

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

En la consolidació±±±n de agosto 2026 se eliminaron los siguientes servicios del core:
- Restic (backups)
- Nginx Proxy Manager
- AdGuard Home
- Netdata

Tambié±± ±n se eliminaron stacks completos: dev, finance (Facto), knowledge, personal, security.

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
- [Servers@Home](https://wiki.serversatho.me/) - Guí±± ±as de TrueNAS y Docker

---

**Autor:** Felipe "pipe" Aros Alzamora  
**Email:** pipeaalzamora@gmail.com  
**Ubicació±±±n:** Santiago, Chile  
**Ú± ±ltima actualizació±±±n:** Septiembre 2026
