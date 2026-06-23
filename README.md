# Homelab Pipe Edition

Dotfiles para un homelab local-first: multimedia familiar, cloud privado tipo Google Drive, proyectos propios y wiki local.

El objetivo principal es correr servicios dentro de la red de casa, sin exponerlos a internet. Tailscale queda como opción para administración remota futura.

## Prioridades

1. Multimedia: Jellyfin, Jellyseerr, Sonarr, Radarr, Prowlarr, Bazarr y qBittorrent.
2. Cloud local: Nextcloud para archivos familiares.
3. Proyectos: Forgejo para repos propios y BookStack para wiki.
4. Operación: Homepage, Uptime Kuma, AdGuard Home, Nginx Proxy Manager y Restic.
5. Opcionales útiles: Facto, Piga, Docat, EveryDocs, DailyTxT, Wastebin, Iguana, n8n, Infisical, Excalidraw y Stirling-PDF.

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

La opcion `a` ejecuta esa ruta recomendada. `n8n`, Facto, Piga, Docat, EveryDocs, DailyTxT, Authelia, smarthome, IA local y seguridad publica quedan fuera del camino principal.

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
Excalidraw  http://127.0.0.1:8084
Stirling-PDF http://127.0.0.1:8085
Facto       http://127.0.0.1:8086
Piga        http://127.0.0.1:8087
Docat       http://127.0.0.1:8089
EveryDocs   http://127.0.0.1:8090
EveryDocs API http://127.0.0.1:8091
DailyTxT    http://127.0.0.1:8092
Wastebin    http://127.0.0.1:8093
Iguana      http://127.0.0.1:8094
Authelia    http://127.0.0.1:9091
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
finance.home   -> IP_DEL_SERVIDOR
piga.home      -> IP_DEL_SERVIDOR
docs.home      -> IP_DEL_SERVIDOR
everydocs.home -> IP_DEL_SERVIDOR
everydocs-api.home -> IP_DEL_SERVIDOR
diario.home    -> IP_DEL_SERVIDOR
paste.home     -> IP_DEL_SERVIDOR
issues.home    -> IP_DEL_SERVIDOR
auth.home      -> IP_DEL_SERVIDOR
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
finance.home   -> facto:9000
piga.home      -> piga:9000
docs.home      -> docat:80
everydocs.home -> everydocs-web:80
everydocs-api.home -> everydocs-core:5678
diario.home    -> dailytxt:80
paste.home     -> wastebin:8088
issues.home    -> iguana:8000
auth.home      -> authelia:9091
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

## Finanzas (Facto)

Stack opcional en `stacks/finance/`. Facto queda configurado para español de Chile y pesos chilenos mediante:

- Locale Java `es_CL`.
- Zona horaria `America/Santiago`.
- Configuración versionada en `configs/facto/accounting-config.yml` con `currency: CLP`.

Instalación:

```bash
./install-local.sh   # opción 9
# o en servidor: sudo bash install.sh -> opción 9
# o primera vez directo:
bash stacks/finance/init-facto.sh
```

Si la base ya existe, el instalador solo levanta el stack y preserva `data/facto/config/accounting-config.yml`. Para recrear la base de datos explícitamente usa `bash stacks/finance/init-facto.sh --force`.

## Conocimiento (Piga + Docat + EveryDocs + DailyTxT + Wastebin + Iguana)

Stack opcional en `stacks/knowledge/`:

- **Piga** (`127.0.0.1:8087`): editor de listas/notas con atajos de productividad. Requiere MariaDB y un primer arranque de inicialización.
- **Docat** (`127.0.0.1:8089`): hosting local para documentación estática versionada. Persiste en `data/docat/`.
- **EveryDocs** (`127.0.0.1:8090`, API `127.0.0.1:8091`): gestor simple de documentos PDF. Persiste archivos en `data/everydocs/files/` y MariaDB en `data/everydocs/db/`.
- **DailyTxT** (`127.0.0.1:8092`): diario web cifrado. Persiste entradas y adjuntos en `data/dailytxt/`.
- **Wastebin** (`127.0.0.1:8093`): pastebin local con SQLite en `data/wastebin/state.db`. No trae autenticación propia; si lo publicas, ponlo detrás de Authelia/NPM con rate-limit.
- **Iguana** (`127.0.0.1:8094`): gestión de tickets y proyectos. La imagen se construye localmente desde `https://github.com/iguana-project/iguana` porque el proyecto no publica una imagen Docker estable.

Instalación:

```bash
./install-local.sh   # opción 10
# o en servidor: sudo bash install.sh -> opción 10
# o primera vez directo:
bash stacks/knowledge/init-piga.sh
```

Piga crea el usuario `admin` con contraseña inicial `changeme`; cámbiala en `http://localhost:8087/app/useradministration`. Si la base ya existe, el instalador no ejecuta `dropAndCreateNewDb`; para recrearla explícitamente usa `bash stacks/knowledge/init-piga.sh --force`.

DailyTxT arranca con registro habilitado (`DAILYTXT_ALLOW_REGISTRATION=true`) para crear el primer usuario. Deshabilítalo después desde `env/.env` o desde el panel admin. La contraseña admin inicial se controla con `DAILYTXT_ADMIN_PASSWORD`.

EveryDocs queda pinneado a `jonashellmann/everydocs:1.5.0` y `jonashellmann/everydocs-web:1.5.0`. No uses `latest` ahí sin probar migraciones: al 20 de junio de 2026, `core:latest` y `web:latest` no apuntan a versiones equivalentes y el core más nuevo falla creando la base inicial.

Wastebin necesita una clave de firma de al menos 64 bytes (`WASTEBIN_SIGNING_KEY`). `scripts/generate-local-env.sh` la genera automáticamente; si creas el `.env` a mano usa `openssl rand -base64 64`.

Iguana se construye con `IGUANA_USE_NGINX=true` para que el Nginx embebido exponga el puerto `8000`. Crea `data/iguana/settings.json` en el primer arranque y genera `SECRET_KEY`, zona horaria e idioma desde el entorno. Si lo expones fuera de localhost, revisa `HOST` y `ALLOWED_HOSTS` en ese archivo.

## Seguridad SSO (Authelia)

Stack opcional en `stacks/security/`. La configuración vive en `configs/authelia/` y se copia a `data/authelia/config/`.

Instalación:

```bash
./install-local.sh   # opción 11
# o en servidor: sudo bash install.sh -> opción 11
# o directo:
docker compose --env-file env/.env -f stacks/security/docker-compose.yml up -d
```

Authelia queda escuchando solo en `127.0.0.1:9091`. El usuario inicial es `pipe` con contraseña `changeme`; cámbiala antes de exponerlo detrás de Nginx Proxy Manager. Para usar dominios reales, ajusta `configs/authelia/configuration.yml`, especialmente `session.cookies[].domain`, `authelia_url`, `default_redirection_url` y las reglas de `access_control`.

## Productividad (Excalidraw + Stirling-PDF)

Stack opcional en `stacks/productivity/`:

- **Excalidraw** (`127.0.0.1:8084`): pizarra para diagramas y bocetos a mano alzada. Es 100% client-side, no guarda nada en el servidor, así que no necesita base de datos ni volúmenes.
- **Stirling-PDF** (`127.0.0.1:8085`): suite local para manipular PDF (unir, dividir, comprimir, OCR, convertir, firmar, etc.). Sus datos persisten en `data/stirling-pdf/`.

Instalación:

```bash
./install-local.sh   # opción 8
# o en servidor: sudo bash install.sh -> opción 8
# o directo:
docker compose --env-file env/.env -f stacks/productivity/docker-compose.yml up -d
```

Nota: las versiones recientes de Stirling-PDF arrancan con login activado. Credenciales por defecto `admin` / `stirling`; cámbialas en el primer acceso desde la configuración de cuenta.

## Notas De Seguridad

- No expongas servicios a internet al inicio.
- Cambia credenciales por defecto en el primer login.
- No uses `latest` para servicios criticos.
- Revisa backups con pruebas de restore.
- Activa acceso por llave SSH antes de deshabilitar password login.
