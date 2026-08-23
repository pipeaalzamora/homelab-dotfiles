# Homelab Pipe Edition

Dotfiles para un homelab local-first simplificado: streaming multimedia familiar, gestión de secretos, herramientas de productividad y gestión de contenedores con dashboard centralizado.

Todo se instala a través de **2 scripts únicos** que verifican requisitos, detectan la IP, generan contraseñas seguras y despliegan todo el stack automáticamente.

---

## 🚀 Instalación Rápida

### 🪟 Windows (PowerShell)

Abre PowerShell en la carpeta del repositorio y ejecuta:

```powershell
.\install.ps1
```

> **Nota:** En Windows, asegúrate de tener **Docker Desktop** iniciado antes de ejecutar el script.

### 🐧 Linux / macOS (Bash)

```bash
chmod +x install.sh
./install.sh
```

---

## 📦 ¿Qué incluye el Stack?

Al finalizar la instalación, se genera un archivo `POST-INSTALL-README.md` en el directorio de tu homelab con todas las URLs y accesos.

| Categoría | Servicio | Descripción | Puerto |
|-----------|----------|-------------|--------|
| **Core** | **Homepage** | Dashboard central del homelab | 3001 |
| | **Portainer** | Gestión visual de contenedores Docker | 9443 |
| | **Infisical** | Gestión centralizada de secretos | 8083 |
| **Media** | **Jellyfin** | Servidor de streaming multimedia | 8096 |
| | **Jellyseerr** | Solicitudes de películas y series | 5055 |
| | **Sonarr** | Automatización de series | 8989 |
| | **Radarr** | Automatización de películas | 7878 |
| | **Prowlarr** | Gestión de indexadores Torrent | 9696 |
| | **FlareSolverr**| Bypass Cloudflare para Prowlarr | 8191 |
| | **Bazarr** | Descarga automática de subtítulos | 6767 |
| | **qBittorrent** | Cliente de descargas Torrent | 8081 |
| **Productividad**| **Excalidraw** | Pizarra de diagramación | 8084 |
| | **Stirling-PDF** | Suite de herramientas PDF | 8085 |
| | **AppFlowy** | Alternativa Notion self-hosted | 8095 |
| **Backups** | **Restic** | Copias de seguridad cifradas | Daemon |

---

## 🛠️ Estructura del Repositorio

```txt
.
├── install.ps1                 # Instalador único para Windows (PowerShell)
├── install.sh                  # Instalador único para Linux/macOS (Bash)
├── stacks/                     # Definiciones Docker Compose
│   ├── core/                   # Portainer, DockerProxy, Homepage
│   ├── secrets/                # Infisical, PostgreSQL, Redis
│   ├── media/                  # Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent
│   ├── productivity/           # Excalidraw, Stirling-PDF
│   ├── appflowy/               # AppFlowy Cloud
│   └── backups/                # Restic
├── configs/                    # Archivos de configuración base y plantillas
│   ├── homepage/               # Configuración del dashboard Homepage
│   ├── env.template            # Plantilla para generación de .env
│   └── POST-INSTALL-README.template.md
└── env/
    └── .env.example
```

---

## 📋 Proceso de Instalación (8 Fases)

Ambos scripts ejecutan automáticamente la misma secuencia:

1. **Verificación de Requisitos**: Docker Engine / Desktop, Docker Compose v2, Git, estado del daemon y recursos de sistema (RAM/Disco).
2. **Detección de IP**: Detecta tu IP local en la red (LAN) y confirma su uso.
3. **Generación de Entorno (`.env`)**: Crea credenciales y claves criptográficas aleatorias.
4. **Estructura de Directorios**: Crea las carpetas de datos persistentes en tu carpeta de usuario.
5. **Configuraciones**: Copia y sustituye variables en las configuraciones de Homepage.
6. **Despliegue de Stacks**: Inicializa la red de Docker y levanta los contenedores en orden.
7. **Verificación de Estado**: Muestra un resumen del estado de ejecución (`✅` / `❌`) de cada contenedor.
8. **README Post-Instalación**: Genera `POST-INSTALL-README.md` con las URLs exactas y credenciales generadas.
