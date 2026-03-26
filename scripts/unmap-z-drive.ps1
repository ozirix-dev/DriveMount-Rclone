<#
.SYNOPSIS
Removes the configured DriveMount-Rclone drive mapping.

.DESCRIPTION
Safely removes the configured drive letter if it is currently mapped in the
current user session.

.EXAMPLE
.\scripts\unmap-z-drive.ps1
#>
param(
    [string]$DriveLetter
)

$ErrorActionPreference = 'Stop'

$common = Join-Path $PSScriptRoot 'DriveMount-Rclone.common.ps1'
. $common

$runtime = Get-DriveMountRcloneRuntimeSettings -Overrides $PSBoundParameters
$driveState = Test-DriveMountRcloneDriveMappingState -RuntimeSettings $runtime

if (-not $driveState.DriveVisibleInShell) {
    Write-Host "$($runtime.DriveLetter) is not mapped."
    return
}

Write-Host "Removing $($runtime.DriveLetter) mapping..."
net use $($runtime.DriveLetter) /delete /y | Out-Null

if ($LASTEXITCODE -eq 0) {
    Remove-PSDrive -Name ($runtime.DriveLetter.TrimEnd(':')) -Force -ErrorAction SilentlyContinue
    Write-Host "$($runtime.DriveLetter) removed."
    return
}

throw "Failed to remove $($runtime.DriveLetter)"
