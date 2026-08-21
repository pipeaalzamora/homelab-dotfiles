# Homelab Dotfiles

Un único stack Docker Compose para el homelab, instalado mediante uno de dos scripts: Linux o Windows. Los scripts validan los requisitos antes de modificar servicios, crean `.env` desde `env/.env.example` si no existe, generan secretos seguros solo para valores marcados como vacíos o `CHANGE_ME`, validan cada Compose y arrancan todos los stacks encontrados en `stacks/`.

> `.env` contiene secretos y no debe subirse al repositorio. El instalador nunca reemplaza un `.env` existente.

## Compatibilidad

Este homelab es compatible con:
- **Linux** (Debian, Ubuntu, etc.) - Scripts Bash
- **macOS** - Scripts Bash  
- **Windows** - Scripts PowerShell

Para usuarios de Windows, consulta la [**Guía de Instalación para Windows**](WINDOWS.md) con instrucciones específicas.

## Prioridades

- Docker Engine (Linux) o Docker Desktop en ejecución (Windows).
- Docker Compose v2, disponible como `docker compose`.
- Python 3.8 o superior.
- Linux: `openssl` y `awk` para crear secretos y detectar la IP.

Los instaladores fallan antes de desplegar si falta cualquiera de los requisitos.

```txt
.
├── install.sh                  # Linux/macOS
├── install.ps1                 # Windows
├── install-local.sh            # Linux/macOS (local)
├── install-local.ps1           # Windows (local)
├── scripts/
│   ├── 01-base.sh              # Linux/macOS
│   ├── 02-docker.sh            # Linux/macOS
│   ├── 03-dirs.sh              # Linux/macOS
│   ├── 03-dirs.ps1             # Windows
│   ├── 04-tailscale.sh         # Linux/macOS
│   ├── generate-local-env.sh   # Linux/macOS
│   └── generate-local-env.ps1  # Windows
├── stacks/
│   ├── core/       # Portainer, NPM, AdGuard, Homepage, Uptime Kuma
│   ├── media/      # Jellyfin + arr + qBittorrent
│   ├── personal/   # Nextcloud
│   ├── dev/        # Forgejo + BookStack
│   ├── backups/    # Restic
│   ├── tools/      # Opcional: n8n
│   ├── secrets/    # Opcional: Infisical (gestión de secretos)
│   ├── productivity/ # Opcional: Excalidraw + Stirling-PDF
│   ├── finance/    # Opcional: Facto
│   ├── knowledge/  # Opcional: Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana
│   ├── smarthome/  # Opcional futuro
│   └── security/   # Opcional: Authelia
├── configs/
│   ├── authelia/
│   ├── everydocs/
│   ├── facto/
│   └── homepage/
└── env/
    └── .env.example
```

## Instalacion Local En Este PC

### Linux / macOS

Para probarlo en tu computador actual, usa:

```bash
git clone https://github.com/pipeaalzamora/homelab-dotfiles.git
cd homelab-dotfiles
chmod +x install-linux.sh
./install-linux.sh
```

### Windows

Abre PowerShell y ejecuta:

```powershell
git clone https://github.com/pipeaalzamora/homelab-dotfiles.git
cd homelab-dotfiles
Set-ExecutionPolicy -Scope Process Bypass
.\install-windows.ps1
```

## Acceso y verificación

Si Docker responde con permiso denegado, corrige el acceso en una terminal normal:

```bash
docker ps
```

Si `/var/run/docker.sock` no pertenece al grupo `docker`, reinicia Docker o el equipo y vuelve a probar.

### Windows

Para Windows, usa PowerShell:

```powershell
Copy-Item env\.env.example env\.env
notepad env\.env
.\install-local.ps1
```

Por defecto usa:

```txt
C:\Users\TU_USUARIO\homelab
```

Ese path se controla con `HOMELAB_ROOT` en `env\.env`.

**Nota importante:** En Windows, Docker Desktop debe estar ejecutándose antes de lanzar el instalador.

### Común para todos los sistemas

El instalador local no toca SSH, UFW, Tailscale ni paquetes del sistema. Solo crea carpetas, copia configs y levanta stacks Docker.

## Discos Recomendados Para Servidor Dedicado

Con SSD de 256 GB y HDD de 8 TB:

```txt
HOMELAB_ROOT/data      -> SSD: configs, bases de datos y estado de contenedores
HOMELAB_ROOT/cloud     -> HDD: archivos de Nextcloud
HOMELAB_ROOT/media     -> HDD: peliculas, series, musica y descargas
HOMELAB_ROOT/backups   -> HDD o destino externo temporal
```

Para revisar un stack concreto, ejecuta desde su carpeta:

### Linux (Debian, Ubuntu, etc.)

```bash
cd stacks/<nombre-del-stack>
docker compose ps
docker compose logs -f
```

### Windows Server

```powershell
# Ejecutar PowerShell como Administrador
Copy-Item env\.env.example env\.env
notepad env\.env
.\install.ps1
```

### Común para todos los sistemas

Ruta recomendada en el instalador:

| Elemento | Ubicación | Uso |
|---|---|---|
| Variables y secretos generados | `.env` | Valores compartidos que consumen los archivos Compose; edítalos solo si el servicio lo requiere |
| Plantilla de variables | `env/.env.example` | Define variables nuevas; borra `.env` únicamente si quieres regenerarlo intencionalmente |
| Servicios Docker | `stacks/<stack>/docker-compose.yml` | Puertos, imágenes, volúmenes, redes y dependencias de cada grupo |
| Homepage | `configs/homepage/` | Enlaces y ajustes de Homepage: `services.yaml`, `settings.yaml`, `widgets.yaml` y `docker.yaml` |
| Otros servicios con configuración propia | `configs/<servicio>/` | Archivos persistentes de Authelia, EveryDocs, Facto y los demás servicios |

Después de modificar Compose, aplica únicamente ese stack con `docker compose up -d`. Después de modificar `configs/homepage/`, reinicia el contenedor de Homepage desde el stack que lo declara.

## Operación

- Ver logs de todos los servicios: `docker ps` y luego `docker logs -f <contenedor>`.
- Detener un stack: desde `stacks/<nombre-del-stack>`, ejecuta `docker compose down`.
- Actualizar imágenes: desde cada stack, ejecuta `docker compose pull && docker compose up -d`.
- Reejecutar el instalador es seguro: conserva `.env`, valida los Compose y reconcilia los servicios.
