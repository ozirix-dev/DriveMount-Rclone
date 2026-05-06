<#
.SYNOPSIS
Maps the configured drive letter to the project WebDAV endpoint.

.DESCRIPTION
Validates that the expected rclone WebDAV listener is active before mapping
the Windows drive letter to the configured localhost WebDAV URL.

.EXAMPLE
.\scripts\map-z-drive.ps1
#>
param(
    [string]$DriveLetter,
    [int]$ListenPort,
    [string]$RemoteName,
    [string]$ListenAddress,
    [string]$WebDavUrl,
    [string]$ExpectedDisplayRoot
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters

Write-Host ''
Write-Host 'Checking WebClient service...'
$service = Get-Service -Name WebClient -ErrorAction SilentlyContinue
if (-not $service) {
    throw 'WebClient service not found.'
}

if ($service.Status -ne 'Running') {
    Start-Service -Name WebClient
    Write-Host 'WebClient service started'
}
else {
    Write-Host 'WebClient already running'
}

Write-Host ''
Write-Host "Checking listener $($runtime.ListenAddress)..."
$listenerState = Get-DriveMountRcloneWebDavListenerState -RuntimeSettings $runtime
if (-not $listenerState.ListenerActive) {
    throw "$($runtime.ListenAddress) is DOWN"
}

if (-not $listenerState.ProcessOwnedByProject) {
    throw "Listener on $($runtime.ListenAddress) is not the expected project process. $($listenerState.Reason)"
}

Write-Host "$($runtime.ListenAddress) is UP and owned by the project"

Write-Host ''
Write-Host "Checking if $($runtime.DriveLetter) already mapped..."
$driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime
if ($driveState.DriveVisibleInShell) {
    if ($driveState.DrivePointsToExpectedRoot) {
        Write-Host "$($runtime.DriveLetter) already exists. Exiting."
        return
    }

    throw "$($runtime.DriveLetter) already exists but points to '$($driveState.ActualDisplayRoot)'."
}

Write-Host ''
Write-Host "Mapping $($runtime.DriveLetter) drive..."
net use $($runtime.DriveLetter) $runtime.WebDavUrl /user:ignored ignored /persistent:no | Out-Null

if ($LASTEXITCODE -eq 0) {
    $driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime
    if (-not $driveState.DrivePointsToExpectedRoot) {
        throw "$($runtime.DriveLetter) mapping did not resolve to $($runtime.ExpectedDisplayRoot)."
    }

    Write-Host "$($runtime.DriveLetter) successfully mapped"
    return
}

throw "$($runtime.DriveLetter) mapping failed"
