# 🚀 Homelab - Post Instalación

¡Tu homelab ha sido desplegado exitosamente! Aquí tienes la información necesaria para acceder y administrar tus servicios.

## 🌐 Servicios Disponibles

| Servicio | URL | Credenciales por Defecto |
|---------|-----|--------------------|
| **Homepage** | http://__HOST_IP__:3001 | - |
| **Portainer** | https://__HOST_IP__:9443 | Crear admin en primer acceso |
| **Infisical** | http://__HOST_IP__:8083 | Crear cuenta en primer acceso |
| **Jellyfin** | http://__HOST_IP__:8096 | Configurar en primer acceso |
| **Jellyseerr** | http://__HOST_IP__:5055 | Configurar en primer acceso |
| **Sonarr** | http://__HOST_IP__:8989 | - |
| **Radarr** | http://__HOST_IP__:7878 | - |
| **Prowlarr** | http://__HOST_IP__:9696 | - |
| **Bazarr** | http://__HOST_IP__:6767 | - |
| **qBittorrent** | http://__HOST_IP__:8081 | admin / (ver logs) |
| **Excalidraw** | http://__HOST_IP__:8084 | - |
| **Stirling PDF** | http://__HOST_IP__:8085 | - |
| **AppFlowy** | http://__HOST_IP__:8095 | pipe@homelab.local / __APPFLOWY_PASS__ |

## 📁 Archivos de Configuración
- Los volúmenes y configuraciones se encuentran en: __HOMELAB_ROOT__\data
- Las contraseñas y secretos están en: __ENV_FILE__

## 🔄 Cómo reiniciar un stack
Ve a la carpeta del repositorio y ejecuta:
```powershell
docker compose --env-file env\.env -f stacks\<nombre>\docker-compose.yml down
docker compose --env-file env\.env -f stacks\<nombre>\docker-compose.yml up -d
```

## 📝 Ver logs
Para ver los logs de un contenedor específico:
```powershell
docker logs -f <nombre_del_contenedor>
```
