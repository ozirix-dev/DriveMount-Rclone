<# 
.SYNOPSIS
Bootstraps DriveMount-Rclone on a Windows machine.

.DESCRIPTION
Installs or validates rclone, ensures the configured remote exists, starts WebClient,
and optionally launches the standard DriveMount-Rclone startup chain.

.PARAMETER ProjectRoot
Project root used for local logs and script coordination.

.PARAMETER NoInstall
Skip rclone installation if the executable is missing.

.PARAMETER NoRemoteConfig
Skip the interactive rclone config wizard if the remote is missing.

.PARAMETER NoStart
Prepare prerequisites without starting and mapping the drive.

.EXAMPLE
.\scripts\bootstrap-z-drive.ps1

.EXAMPLE
.\scripts\bootstrap-z-drive.ps1 -NoStart
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
    [switch]$NoInstall,
    [switch]$NoRemoteConfig,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1')

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters

$logDir = Ensure-DriveMountRcloneLogDirectory -ProjectRoot $ProjectRoot -LogDirectoryName $runtime.LogDirectoryName
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcript = Join-Path $logDir ("bootstrap-z-drive-$timestamp.log")
$transcriptStarted = $false

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

    $rclonePath = Install-RcloneIfNeeded -AllowInstall (-not $NoInstall)
    Ensure-RemoteConfigured -RclonePath $rclonePath -RemoteName $runtime.RemoteName -AllowConfig (-not $NoRemoteConfig)

    try {
        Start-Transcript -Path $transcript -ErrorAction Stop | Out-Null
        $transcriptStarted = $true
    }
    catch {
        Write-Warning "Could not start transcript at $transcript"
    }

    Write-Host "Transcript: $transcript"
    Write-Host 'Transcript started after prerequisite auth/config checks.'

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

        & $startScript `
            -ProjectRoot $ProjectRoot `
            -RemoteName $runtime.RemoteName `
            -DriveLetter $runtime.DriveLetter `
            -ListenPort $runtime.ListenPort `
            -ListenAddress $runtime.ListenAddress `
            -WebDavUrl $runtime.WebDavUrl `
            -ExpectedDisplayRoot $runtime.ExpectedDisplayRoot `
            -LogDirectoryName $runtime.LogDirectoryName `
            -RcloneLogFileName $runtime.RcloneLogFileName `
            -UseTranscript:$false

        $driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime
        if (-not $driveState.DriveVisibleInShell -or -not $driveState.DrivePointsToExpectedRoot) {
            throw (("{0} did not become available after bootstrap. Actual root: {1}" -f $runtime.DriveLetter, $driveState.ActualDisplayRoot))
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
