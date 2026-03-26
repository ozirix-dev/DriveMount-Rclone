param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RemoteName = 'rclone-google:',
    [string]$ListenAddress = '127.0.0.1:8080',
    [int]$ListenPort = 8080,
    [string]$LogFileName = 'rclone.log',
    [int]$StartupWaitSeconds = 10
)

$ErrorActionPreference = 'Stop'

$LogDir = Join-Path $ProjectRoot 'logs'
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$LogFile = Join-Path $LogDir $LogFileName

$existingListener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $ListenPort -ErrorAction SilentlyContinue
if ($existingListener) {
    $existingProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($existingListener.OwningProcess)" -ErrorAction SilentlyContinue
    if ($existingProcess -and $existingProcess.CommandLine -and $existingProcess.CommandLine -match 'rclone' -and $existingProcess.CommandLine -match 'serve' -and $existingProcess.CommandLine -match 'webdav' -and $existingProcess.CommandLine -match [regex]::Escape($RemoteName)) {
        Write-Host "Rclone WebDAV already listening at $ListenAddress"
        return
    }

    throw "Port $ListenPort is already in use by another process."
}

$rcloneCommand = Get-Command 'rclone.exe' -ErrorAction SilentlyContinue
if (-not $rcloneCommand) {
    throw 'rclone.exe not found in PATH.'
}

$arguments = @(
    'serve', 'webdav', $RemoteName,
    '--addr', $ListenAddress,
    '--vfs-cache-mode', 'writes',
    '--log-file', $LogFile,
    '--log-level', 'INFO'
)

$process = Start-Process -FilePath $rcloneCommand.Source -ArgumentList $arguments -WindowStyle Hidden -PassThru

$ready = $false
for ($i = 0; $i -lt $StartupWaitSeconds; $i++) {
    Start-Sleep -Seconds 1
    $listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $ListenPort -ErrorAction SilentlyContinue
    if ($listener) {
        $ready = $true
        break
    }

    if ($process.HasExited) {
        break
    }
}

if (-not $ready) {
    throw "Rclone WebDAV did not open $ListenAddress in time."
}

Write-Host "Rclone WebDAV started at $ListenAddress"
Write-Host "Log file: $LogFile"
