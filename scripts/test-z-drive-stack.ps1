param(
    [string]$DriveLetter = 'Z:',
    [int]$ListenPort = 8080,
    [string]$RemoteName = 'rclone-google:'
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$results = [ordered]@{}

$rclonePath = Resolve-DriveMountRcloneExecutable
$results.RcloneExe = [bool]$rclonePath

try {
    $results.RemoteConfigured = Test-DriveMountRcloneRemoteConfigured -RclonePath $rclonePath -RemoteName $RemoteName
} catch {
    $results.RemoteConfigured = $false
}

$webClient = Get-Service -Name WebClient -ErrorAction SilentlyContinue
$results.WebClientRunning = [bool]($webClient -and $webClient.Status -eq 'Running')

$results.ListenerActive = Test-DriveMountRcloneListener -ListenPort $ListenPort

$driveName = $DriveLetter.TrimEnd(':')
$drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$results.DriveVisibleInShell = [bool]$drive
$results.DrivePointsToWebDav = [bool]($drive -and $drive.DisplayRoot -eq '\\localhost@8080\DavWWWRoot')

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
