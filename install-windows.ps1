[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $RootDir '.env'
$HomepagePort = if ($env:HOMEPAGE_PORT) { $env:HOMEPAGE_PORT } else { '3000' }

function Info([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Fail([string]$Message) { throw "ERROR: $Message" }
function Require-Command([string]$Name, [string]$Message) { if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) { Fail $Message } }

function Test-Requirements {
  Info 'Comprobando requisitos'
  if (-not $IsWindows) { Fail 'Usa install-linux.sh en Linux.' }
  Require-Command docker 'Docker Desktop no está instalado o no está en PATH.'
  try { docker info | Out-Null } catch { Fail 'Docker Desktop no está ejecutándose.' }
  try { docker compose version | Out-Null } catch { Fail 'Docker Compose v2 no está disponible.' }
  Require-Command python 'Python 3 no está instalado o no está en PATH.'
  $pythonVersion = (& python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  if ([version]$pythonVersion -lt [version]'3.8') { Fail 'Se requiere Python 3.8 o superior.' }
  if (-not (Test-Path (Join-Path $RootDir 'stacks'))) { Fail 'No se encontró el directorio stacks/.' }
}

function New-Secret {
  $bytes = New-Object byte[] 36
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return ([Convert]::ToBase64String($bytes).Replace('+','-').Replace('/','_').Replace('=','')).Substring(0,48)
}

function Initialize-Env {
  $template = Join-Path $RootDir 'env/.env.example'
  if (-not (Test-Path $template)) { Info 'No hay env/.env.example; se omite .env'; return }
  if (Test-Path $EnvFile) { Info 'Se conserva .env existente'; return }
  Info 'Generando .env con secretos aleatorios'
  $result = foreach ($line in Get-Content $template) {
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line) -or $line -notmatch '=') { $line; continue }
    $key, $value = $line -split '=', 2
    if ($key -match 'SECRET|PASSWORD|PASS|TOKEN|KEY|JWT|SALT' -and ($value -eq '' -or $value -match '^(CHANGE_ME|CHANGEME|REPLACE_ME|example|your_.*)$')) { $value = New-Secret }
    "$key=$value"
  }
  Set-Content -Path $EnvFile -Value $result -NoNewline
}

function Get-ComposeFiles {
  Get-ChildItem -Path (Join-Path $RootDir 'stacks') -Recurse -File | Where-Object { $_.Name -in @('compose.yml','compose.yaml','docker-compose.yml','docker-compose.yaml') } | Sort-Object FullName
}

function Install-Stack {
  $files = @(Get-ComposeFiles)
  if ($files.Count -eq 0) { Fail 'No se encontraron archivos Docker Compose en stacks/.' }
  foreach ($file in $files) {
    Info "Validando $($file.FullName.Substring($RootDir.Length + 1))"
    Push-Location $file.DirectoryName
    try { docker compose --env-file $EnvFile -f $file.FullName config -q; docker compose --env-file $EnvFile -f $file.FullName up -d } finally { Pop-Location }
  }
}

function Show-Report {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' -and $_.InterfaceAlias -notmatch 'vEthernet|Loopback' } | Select-Object -First 1 -ExpandProperty IPAddress)
  $ports = docker ps --format '{{.Names}} {{.Ports}}'
  $homepage = $ports | Where-Object { $_ -match 'homepage' } | Select-Object -First 1
  $port = if ($homepage -match '0.0.0.0:(\d+)') { $Matches[1] } else { $HomepagePort }
  Info 'Estado de los contenedores'
  docker ps --format 'table {{.Names}}`t{{.Status}}`t{{.Ports}}'
  Write-Host "`nHomepage: http://$($ip ?? 'localhost'):$port"
  Write-Host "Local:    http://localhost:$port"
  Write-Host "Configuración: $(Join-Path $RootDir 'configs')"
  Write-Host "Variables y secretos: $EnvFile"
}

Test-Requirements
Initialize-Env
Install-Stack
Show-Report
