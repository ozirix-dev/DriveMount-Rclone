param(
    [int]$ListenPort = 8080,
    [string]$RemoteName = 'rclone-google:'
)

$ErrorActionPreference = 'Stop'

$listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $ListenPort -ErrorAction SilentlyContinue
if (-not $listener) {
    Write-Host "No listener found on port $ListenPort."
    return
}

$process = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)" -ErrorAction SilentlyContinue
if (-not $process) {
    throw "Could not inspect process for PID $($listener.OwningProcess)."
}

if ($process.CommandLine -notmatch 'rclone' -or $process.CommandLine -notmatch 'serve' -or $process.CommandLine -notmatch 'webdav' -or $process.CommandLine -notmatch [regex]::Escape($RemoteName)) {
    throw "Refusing to stop non-project process on port $ListenPort."
}

Stop-Process -Id $listener.OwningProcess -Force
Write-Host "Stopped rclone WebDAV process on port $ListenPort."
