param(
    [string]$DriveLetter = 'Z:',
    [int]$ListenPort = 8080,
    [string]$RemoteName = 'rclone-google:'
)

$ErrorActionPreference = 'Stop'

$results = [ordered]@{}

$results.RcloneExe = [bool](Get-Command 'rclone.exe' -ErrorAction SilentlyContinue)

try {
    $remoteList = & rclone listremotes 2>$null
    $results.RemoteConfigured = $remoteList -contains $RemoteName
} catch {
    $results.RemoteConfigured = $false
}

$webClient = Get-Service -Name WebClient -ErrorAction SilentlyContinue
$results.WebClientRunning = [bool]($webClient -and $webClient.Status -eq 'Running')

$listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $ListenPort -ErrorAction SilentlyContinue
$results.ListenerActive = [bool]$listener

$driveName = $DriveLetter.TrimEnd(':')
$drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$results.DriveVisibleInShell = [bool]$drive
$results.DrivePointsToWebDav = [bool]($drive -and $drive.DisplayRoot -eq '\\localhost@8080\DavWWWRoot')

Write-Host 'DriveMount-Rclone status'
foreach ($key in $results.Keys) {
    Write-Host ("{0,-22} {1}" -f ($key + ':'), $(if ($results[$key]) { 'OK' } else { 'FAIL' }))
}

if ($results.Values -contains $false) {
    exit 1
}

exit 0
