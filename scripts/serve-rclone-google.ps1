<#
.SYNOPSIS
Starts the project-controlled rclone WebDAV listener.

.DESCRIPTION
Starts rclone serve webdav on the configured localhost endpoint, reuses the
current listener if it already belongs to this project, and writes rclone logs
to the local logs folder.

.PARAMETER ProjectRoot
Project root used for local logs.

.EXAMPLE
.\scripts\serve-rclone-google.ps1
#>
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RemoteName,
    [int]$ListenPort,
    [string]$ListenAddress,
    [string]$LogDirectoryName,
    [string]$RcloneLogFileName,
    [int]$StartupWaitSeconds = 10
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters
$listenerState = Get-DriveMountRcloneWebDavListenerState -RuntimeSettings $runtime
$LogDir = Ensure-DriveMountRcloneLogDirectory -ProjectRoot $ProjectRoot -LogDirectoryName $runtime.LogDirectoryName

$LogFile = Join-Path $LogDir $runtime.RcloneLogFileName

if ($listenerState.ListenerActive) {
    if ($listenerState.ProcessOwnedByProject) {
        Write-Host "Rclone WebDAV already listening at $($runtime.ListenAddress)"
        return
    }

    throw "Port $($runtime.ListenPort) is already in use by another process. $($listenerState.Reason)"
}

$rclonePath = Resolve-DriveMountRcloneExecutable
if (-not $rclonePath) {
    throw 'rclone.exe not found in PATH or known local install locations.'
}

$arguments = @(
    'serve', 'webdav', $runtime.RemoteName,
    '--addr', $runtime.ListenAddress,
    '--vfs-cache-mode', 'writes',
    '--log-file', $LogFile,
    '--log-level', 'INFO'
)

$process = Start-Process -FilePath $rclonePath -ArgumentList $arguments -WindowStyle Hidden -PassThru

$ready = $false
for ($i = 0; $i -lt $StartupWaitSeconds; $i++) {
    Start-Sleep -Seconds 1
    $listenerState = Get-DriveMountRcloneWebDavListenerState -RuntimeSettings $runtime
    if ($listenerState.ListenerActive -and $listenerState.ProcessOwnedByProject) {
        $ready = $true
        break
    }

    if ($process.HasExited) {
        break
    }
}

if (-not $ready) {
    throw "Rclone WebDAV did not open $($runtime.ListenAddress) in time."
}

Write-Host "Rclone WebDAV started at $($runtime.ListenAddress)"
Write-Host "Log file: $LogFile"
