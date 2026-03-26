<#
.SYNOPSIS
Starts the normal DriveMount-Rclone operator chain.

.DESCRIPTION
Starts the rclone WebDAV process if needed, maps the configured drive letter,
and verifies the expected drive mapping is present in the current session.

.PARAMETER ProjectRoot
Project root used for local logs and script coordination.

.PARAMETER UseTranscript
Enable or disable the wrapper transcript log.

.EXAMPLE
.\scripts\start-z-drive.ps1

.EXAMPLE
.\scripts\start-z-drive.ps1 -UseTranscript:$false
#>
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RemoteName,
    [string]$DriveLetter,
    [int]$ListenPort,
    [string]$ListenAddress,
    [string]$WebDavUrl,
    [string]$ExpectedDisplayRoot,
    [string]$LogDirectoryName,
    [string]$RcloneLogFileName,
    [bool]$UseTranscript = $true
)

$ErrorActionPreference = 'Stop'

$serveScript = Join-Path $PSScriptRoot 'serve-rclone-google.ps1'
$mapScript = Join-Path $PSScriptRoot 'map-z-drive.ps1'
$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters

$logDir = Ensure-DriveMountRcloneLogDirectory -ProjectRoot $ProjectRoot -LogDirectoryName $runtime.LogDirectoryName

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

    & $serveScript `
        -ProjectRoot $ProjectRoot `
        -RemoteName $runtime.RemoteName `
        -ListenPort $runtime.ListenPort `
        -ListenAddress $runtime.ListenAddress `
        -LogDirectoryName $runtime.LogDirectoryName `
        -RcloneLogFileName $runtime.RcloneLogFileName

    & $mapScript `
        -DriveLetter $runtime.DriveLetter `
        -ListenPort $runtime.ListenPort `
        -RemoteName $runtime.RemoteName `
        -ListenAddress $runtime.ListenAddress `
        -WebDavUrl $runtime.WebDavUrl `
        -ExpectedDisplayRoot $runtime.ExpectedDisplayRoot

    $driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime
    if (-not $driveState.DriveVisibleInShell -or -not $driveState.DrivePointsToExpectedRoot) {
        throw (("{0} did not become available after start. Actual root: {1}" -f $runtime.DriveLetter, $driveState.ActualDisplayRoot))
    }

    Write-Host 'DriveMount-Rclone start sequence finished.'
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
