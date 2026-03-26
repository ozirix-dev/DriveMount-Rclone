param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [bool]$UseTranscript = $true
)

$ErrorActionPreference = 'Stop'

$serveScript = Join-Path $PSScriptRoot 'serve-rclone-google.ps1'
$mapScript = Join-Path $PSScriptRoot 'map-z-drive.ps1'
$logDir = Join-Path $ProjectRoot 'logs'
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcript = Join-Path $logDir ("start-z-drive-$timestamp.log")

if ($UseTranscript) {
    $transcriptStarted = $false
    try {
        Start-Transcript -Path $transcript -ErrorAction Stop | Out-Null
        $transcriptStarted = $true
    } catch {
        Write-Warning "Could not start transcript at $transcript"
    }
}
else {
    $transcriptStarted = $false
}

try {
    Write-Host ''
    Write-Host 'DriveMount-Rclone start sequence started...'
    if ($UseTranscript) {
        Write-Host "Transcript: $transcript"
    }
    else {
        Write-Host 'Transcript: disabled'
    }

    if (-not (Test-Path $serveScript)) {
        throw "Missing script: $serveScript"
    }

    if (-not (Test-Path $mapScript)) {
        throw "Missing script: $mapScript"
    }

    & $serveScript
    & $mapScript

    $drive = Get-PSDrive -Name Z -ErrorAction SilentlyContinue
    if (-not $drive -or $drive.DisplayRoot -ne '\\localhost@8080\DavWWWRoot') {
        throw 'Z: did not become available after bootstrap.'
    }

    Write-Host 'DriveMount-Rclone bootstrap finished.'
}
catch {
    Write-Error $_.Exception.Message
    throw
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
}
