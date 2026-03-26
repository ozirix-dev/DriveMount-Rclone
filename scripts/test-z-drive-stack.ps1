<#
.SYNOPSIS
Checks the current DriveMount-Rclone stack state.

.DESCRIPTION
Performs read-only health checks for rclone resolution, remote configuration,
WebClient status, listener ownership, and the current drive mapping.

.EXAMPLE
.\scripts\test-z-drive-stack.ps1
#>
param(
    [string]$DriveLetter,
    [int]$ListenPort,
    [string]$RemoteName,
    [string]$ListenAddress
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters
$results = [ordered]@{}

$rclonePath = Resolve-DriveMountRcloneExecutable
$results.RcloneExe = [bool]$rclonePath

try {
    $results.RemoteConfigured = Test-DriveMountRcloneRemoteConfigured -RclonePath $rclonePath -RemoteName $runtime.RemoteName
} catch {
    $results.RemoteConfigured = $false
}

$webClient = Get-Service -Name WebClient -ErrorAction SilentlyContinue
$results.WebClientRunning = [bool]($webClient -and $webClient.Status -eq 'Running')

$listenerState = Get-DriveMountRcloneWebDavListenerState -RuntimeSettings $runtime
$results.ListenerActive = $listenerState.ListenerActive
$results.ListenerOwnedByProject = $listenerState.ProcessOwnedByProject

$driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime
$results.DriveVisibleInShell = $driveState.DriveVisibleInShell
$results.DrivePointsToExpectedRoot = $driveState.DrivePointsToExpectedRoot

Write-Host 'DriveMount-Rclone status'
foreach ($key in $results.Keys) {
    Write-Host ("{0,-22} {1}" -f ($key + ':'), $(if ($results[$key]) { 'OK' } else { 'FAIL' }))
}

if ($results.Values -contains $false) {
    Write-Host 'One or more checks failed.'
    exit 1
}

Write-Host 'All checks passed.'
exit 0
