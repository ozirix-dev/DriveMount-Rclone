<#
.SYNOPSIS
Stops the project-controlled rclone WebDAV process.

.DESCRIPTION
Stops only the listener that matches the DriveMount-Rclone WebDAV command
line for the configured port and remote.

.EXAMPLE
.\scripts\stop-z-drive.ps1
#>
param(
    [int]$ListenPort,
    [string]$RemoteName,
    [string]$ListenAddress
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters
$listenerState = Get-DriveMountRcloneWebDavListenerState -RuntimeSettings $runtime

if (-not $listenerState.ListenerActive) {
    Write-Host "No listener found on port $($runtime.ListenPort)."
    return
}

if (-not $listenerState.ProcessOwnedByProject) {
    throw "Refusing to stop non-project process on $($runtime.ListenAddress). $($listenerState.Reason)"
}

Stop-Process -Id $listenerState.ProcessId -Force
Write-Host "Stopped rclone WebDAV process on port $($runtime.ListenPort)."
