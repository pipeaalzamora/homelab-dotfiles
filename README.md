# Homelab Dotfiles

Un único stack Docker Compose para el homelab, instalado mediante uno de dos scripts: Linux o Windows. Los scripts validan los requisitos antes de modificar servicios, crean `.env` desde `env/.env.example` si no existe, generan secretos seguros solo para valores marcados como vacíos o `CHANGE_ME`, validan cada Compose y arrancan todos los stacks encontrados en `stacks/`.

> `.env` contiene secretos y no debe subirse al repositorio. El instalador nunca reemplaza un `.env` existente.

## Requisitos

- Docker Engine (Linux) o Docker Desktop en ejecución (Windows).
- Docker Compose v2, disponible como `docker compose`.
- Python 3.8 o superior.
- Linux: `openssl` y `awk` para crear secretos y detectar la IP.

Los instaladores fallan antes de desplegar si falta cualquiera de los requisitos.

## Instalación

### Linux

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

Al terminar, el instalador muestra el estado, puertos y la URL detectada de Homepage. La dirección esperada es `http://IP_DEL_HOST:3000`; usa la URL exacta impresa por el script si el puerto fue configurado de otra forma.

Para comprobar los contenedores después de instalar:

```bash
docker ps
```

```powershell
docker ps
```

Para revisar un stack concreto, ejecuta desde su carpeta:

```bash
cd stacks/<nombre-del-stack>
docker compose ps
docker compose logs -f
```

## Dónde configurar cada cosa

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
