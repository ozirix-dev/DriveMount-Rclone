param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RemoteName = 'rclone-google:',
    [string]$DriveLetter = 'Z:',
    [switch]$NoInstall,
    [switch]$NoRemoteConfig,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1')

$logDir = Ensure-DriveMountRcloneLogDirectory -ProjectRoot $ProjectRoot
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcript = Join-Path $logDir ("bootstrap-z-drive-$timestamp.log")

$transcriptStarted = $false
try {
    Start-Transcript -Path $transcript -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
}
catch {
    Write-Warning "Could not start transcript at $transcript"
}

function Install-RcloneIfNeeded {
    param(
        [bool]$AllowInstall
    )

    $rclonePath = Resolve-DriveMountRcloneExecutable
    if ($rclonePath) {
        return $rclonePath
    }

    if (-not $AllowInstall) {
        throw 'rclone.exe not found. Install rclone or rerun bootstrap with installation enabled.'
    }

    $winget = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'rclone.exe not found and winget is unavailable.'
    }

    Write-Host 'rclone.exe not found. Installing Rclone with winget...'
    & $winget.Source install --id Rclone.Rclone -e --source winget --accept-package-agreements --accept-source-agreements

    $rclonePath = Resolve-DriveMountRcloneExecutable
    if (-not $rclonePath) {
        throw 'Rclone installation did not expose rclone.exe in a known location.'
    }

    return $rclonePath
}

function Ensure-RemoteConfigured {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RclonePath,

        [Parameter(Mandatory = $true)]
        [string]$RemoteName,

        [bool]$AllowConfig
    )

    if (Test-DriveMountRcloneRemoteConfigured -RclonePath $RclonePath -RemoteName $RemoteName) {
        return
    }

    if (-not $AllowConfig) {
        throw "Remote '$RemoteName' is not configured."
    }

    Write-Host "Remote '$RemoteName' is missing."
    Write-Host 'Launching the rclone config wizard in this console.'
    Write-Host "Create or select the remote so that it matches '$RemoteName'."
    & $RclonePath config

    if (-not (Test-DriveMountRcloneRemoteConfigured -RclonePath $RclonePath -RemoteName $RemoteName)) {
        throw "Remote '$RemoteName' is still missing after config."
    }
}

try {
    Write-Host ''
    Write-Host 'DriveMount-Rclone bootstrap started...'
    Write-Host "Transcript: $transcript"

    $rclonePath = Install-RcloneIfNeeded -AllowInstall (-not $NoInstall)
    Ensure-RemoteConfigured -RclonePath $rclonePath -RemoteName $RemoteName -AllowConfig (-not $NoRemoteConfig)

    $webClient = Get-Service -Name WebClient -ErrorAction SilentlyContinue
    if (-not $webClient) {
        throw 'WebClient service not found.'
    }

    if ($webClient.Status -ne 'Running') {
        Start-Service -Name WebClient
        Write-Host 'WebClient service started'
    }
    else {
        Write-Host 'WebClient already running'
    }

    if (-not $NoStart) {
        $startScript = Join-Path $PSScriptRoot 'start-z-drive.ps1'
        if (-not (Test-Path $startScript)) {
            throw "Missing script: $startScript"
        }

        & $startScript -ProjectRoot $ProjectRoot -UseTranscript:$false

        $drive = Get-PSDrive -Name ($DriveLetter.TrimEnd(':')) -ErrorAction SilentlyContinue
        if (-not $drive -or $drive.DisplayRoot -ne '\\localhost@8080\DavWWWRoot') {
            throw "$DriveLetter did not become available after bootstrap."
        }
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
