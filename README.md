# Homelab Pipe Edition

Dotfiles para un homelab local-first: multimedia familiar, cloud privado tipo Google Drive, proyectos propios y wiki local.

El objetivo principal es correr servicios dentro de la red de casa, sin exponerlos a internet. Tailscale queda como opción para administración remota futura.

## Prioridades

1. Multimedia: Jellyfin, Jellyseerr, Sonarr, Radarr, Prowlarr, Bazarr y qBittorrent.
2. Cloud local: Nextcloud para archivos familiares.
3. Proyectos: Forgejo para repos propios y BookStack para wiki.
4. Operación: Homepage, Uptime Kuma, AdGuard Home, Nginx Proxy Manager y Restic.

## Estructura

```txt
.
├── install.sh
├── scripts/
│   ├── 01-base.sh
│   ├── 02-docker.sh
│   ├── 03-dirs.sh
│   └── 04-tailscale.sh
├── stacks/
│   ├── core/       # Portainer, NPM, AdGuard, Homepage, Uptime Kuma
│   ├── media/      # Jellyfin + arr + qBittorrent
│   ├── personal/   # Nextcloud
│   ├── dev/        # Forgejo + BookStack
│   ├── backups/    # Restic
│   ├── tools/      # Opcional: n8n
│   ├── secrets/    # Opcional: Infisical (gestión de secretos)
│   ├── smarthome/  # Opcional futuro
│   └── security/   # Opcional futuro si expones a internet
├── configs/
│   └── homepage/
└── env/
    └── .env.example
```

## Instalacion Local En Este PC

Para probarlo en tu computador actual, usa:

```bash
cp env/.env.example env/.env
nano env/.env
chmod +x install-local.sh
./install-local.sh
```

Por defecto usa:

```txt
/home/pipeaalzamora/homelab
```

Ese path se controla con `HOMELAB_ROOT` en `env/.env`.

El instalador local no toca SSH, UFW, Tailscale ni paquetes del sistema. Solo crea carpetas, copia configs y levanta stacks Docker.

Si Docker responde con permiso denegado, corrige el acceso en una terminal normal:

```bash
sudo groupadd -f docker
sudo usermod -aG docker "$USER"
newgrp docker
docker ps
```

Si `/var/run/docker.sock` no pertenece al grupo `docker`, reinicia Docker o el equipo y vuelve a probar.

## Discos Recomendados Para Servidor Dedicado

Con SSD de 256 GB y HDD de 8 TB:

```txt
HOMELAB_ROOT/data      -> SSD: configs, bases de datos y estado de contenedores
HOMELAB_ROOT/cloud     -> HDD: archivos de Nextcloud
HOMELAB_ROOT/media     -> HDD: peliculas, series, musica y descargas
HOMELAB_ROOT/backups   -> HDD o destino externo temporal
```

Si el HDD se monta en otro punto, ajusta los bind mounts antes de instalar.

## Instalacion En Servidor Dedicado

```bash
cp env/.env.example env/.env
nano env/.env
sudo bash install.sh
```

Ruta recomendada en el instalador:

```txt
1) Base local
2) Multimedia familiar
3) Cloud local
4) Proyectos y wiki local
5) Backups
```

La opcion `a` ejecuta esa ruta recomendada. `n8n`, smarthome, IA local y seguridad publica quedan fuera del camino principal.

## Acceso Local

Servicios familiares:

```txt
Jellyfin    http://IP_DEL_SERVIDOR:8096
Jellyseerr  http://IP_DEL_SERVIDOR:5055
Nextcloud   http://IP_DEL_SERVIDOR:8082
Homepage    http://IP_DEL_SERVIDOR:3001
NPM         http://127.0.0.1:8181
AdGuard UI  http://127.0.0.1:8080
Infisical   http://127.0.0.1:8083
```

Paneles administrativos quedan enlazados a `127.0.0.1` cuando es posible. Para acceder desde tu equipo usa un tunel SSH o configura Nginx Proxy Manager con DNS local.

Ejemplo de tunel:

```bash
ssh -L 9443:127.0.0.1:9443 -L 8989:127.0.0.1:8989 pipe@IP_DEL_SERVIDOR
```

## DNS Local

AdGuard Home puede resolver nombres internos como:

```txt
jellyfin.home  -> IP_DEL_SERVIDOR
requests.home  -> IP_DEL_SERVIDOR
cloud.home     -> IP_DEL_SERVIDOR
git.home       -> IP_DEL_SERVIDOR
wiki.home      -> IP_DEL_SERVIDOR
status.home    -> IP_DEL_SERVIDOR
sonarr.home    -> IP_DEL_SERVIDOR
radarr.home    -> IP_DEL_SERVIDOR
prowlarr.home  -> IP_DEL_SERVIDOR
bazarr.home    -> IP_DEL_SERVIDOR
torrent.home   -> IP_DEL_SERVIDOR
portainer.home -> IP_DEL_SERVIDOR
proxy.home     -> IP_DEL_SERVIDOR
dns.home       -> IP_DEL_SERVIDOR
```

Luego Nginx Proxy Manager puede enrutar esos nombres hacia los contenedores internos:

```txt
jellyfin.home  -> jellyfin:8096
requests.home  -> jellyseerr:5055
cloud.home     -> nextcloud-nginx:80
git.home       -> forgejo:3000
wiki.home      -> bookstack:80
sonarr.home    -> sonarr:8989
radarr.home    -> radarr:7878
prowlarr.home  -> prowlarr:9696
bazarr.home    -> bazarr:6767
torrent.home   -> qbittorrent:8080
status.home    -> uptime-kuma:3001
portainer.home -> portainer:9443
proxy.home     -> npm:81
dns.home       -> adguard:80
```

## Backups

GitHub debe guardar solo:

- Compose files
- Scripts
- Configs sin secretos
- Documentacion

No subas:

- `.env`
- Bases de datos
- Fotos/documentos personales
- Libreria multimedia

Restic queda preparado para respaldar `HOMELAB_ROOT/data`, `HOMELAB_ROOT/cloud` y `HOMELAB_ROOT/homelab`. Para que el backup sea real, usa tambien un destino fuera del servidor: disco USB rotado, NAS, otro equipo o almacenamiento remoto cifrado.

## Infisical (Gestión De Secretos)

Stack opcional para centralizar API keys, credenciales y variables de entorno con cifrado. Vive en `stacks/secrets/` (Infisical + PostgreSQL + Redis) y la UI queda en `127.0.0.1:8083`.

Las claves `INFISICAL_ENCRYPTION_KEY` y `INFISICAL_AUTH_SECRET` son obligatorias; sin ellas el contenedor no arranca. La `ENCRYPTION_KEY` cifra tus secretos, así que si la pierdes no podrás descifrarlos. Genéralas con:

```bash
openssl rand -hex 16      # INFISICAL_ENCRYPTION_KEY
openssl rand -base64 32   # INFISICAL_AUTH_SECRET
```

Instalación:

```bash
./install-local.sh   # opción 7
# o en servidor: sudo bash install.sh -> opción 7
# o directo:
docker compose --env-file env/.env -f stacks/secrets/docker-compose.yml up -d
```

En el primer arranque corre las migraciones de base de datos automáticamente; revisa `docker logs -f infisical` si la UI tarda en cargar. Luego abre `http://localhost:8083` y crea la cuenta admin.

## Notas De Seguridad- No expongas servicios a internet al inicio.
- Cambia credenciales por defecto en el primer login.
- No uses `latest` para servicios criticos.
- Revisa backups con pruebas de restore.
- Activa acceso por llave SSH antes de deshabilitar password login.
