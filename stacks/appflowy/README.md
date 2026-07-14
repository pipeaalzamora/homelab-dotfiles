# Stack: AppFlowy (alternativa self-hosted a Notion)

AppFlowy Cloud es un stack grande (~11 contenedores: postgres, redis, minio,
gotrue, appflowy_cloud, worker, search, web, admin_frontend, nginx y un
servicio de IA opcional). Se mantiene en el repositorio oficial y cambia con
frecuencia, por eso **no vendorizamos su `docker-compose.yml`**: en su lugar
clonamos el repo y configuramos su `.env`.

- Repo oficial: https://github.com/AppFlowy-IO/AppFlowy-Cloud
- Docs: https://appflowy.com/docs/Local-Host-Deployment

## Instalación

```bash
bash stacks/appflowy/install-appflowy.sh
```

El script clona el repo en `$HOMELAB_ROOT/appflowy`, genera un `.env` con
secretos y credenciales seguras (reemplaza los valores por defecto conocidos
de AppFlowy), desactiva el servicio de IA y levanta todo.

## Acceso

Se usa la **IP LAN del host** (no `localhost`), por ejemplo `192.168.1.7`:

- Web:           http://<IP_HOST>:8095
- Consola admin: http://<IP_HOST>:8095/console

En la app de escritorio de AppFlowy: **Settings → server URL →
`http://<IP_HOST>:8095`**.

### ¿Por qué la IP y no localhost?

El `admin_frontend` usa una sola `APPFLOWY_BASE_URL` tanto para las llamadas
del navegador como para las suyas de servidor-a-servidor (dentro de Docker).
Con `localhost` el navegador funciona pero el contenedor no (localhost apunta
a sí mismo); con un hostname interno de Docker (`appflowy_cloud`) es al revés.
La IP LAN del host es alcanzable desde ambos lados, así que resuelve el
conflicto. Ventaja extra: AppFlowy queda accesible desde otros dispositivos de
la red (móvil, etc.).

Las credenciales admin se imprimen al ejecutar el script (email
`pipe@homelab.local`). Cambia la contraseña **solo vía la variable
`GOTRUE_ADMIN_PASSWORD` del `.env`**, no desde la consola admin.

## Puertos

- `8095` → HTTP (nginx interno)
- `8447` → HTTPS/TLS (nginx interno, certs autofirmados del repo)

## IA opcional

El servicio `ai` (búsqueda semántica, resúmenes) requiere una API key de
OpenAI o Azure. Está desactivado vía `docker-compose.override.yml`. Para
habilitarlo: pon `AI_OPENAI_API_KEY=...` en el `.env` y arranca con
`--profile ai`.

## Gestión

Todos los comandos se ejecutan sobre el repo clonado en `$HOMELAB_ROOT/appflowy`:

```bash
cd "$HOMELAB_ROOT/appflowy"
docker compose ps                # estado
docker compose logs -f nginx     # logs
docker compose down              # detener
docker compose down -v           # detener y BORRAR todos los datos
docker compose pull && docker compose up -d   # actualizar
```
