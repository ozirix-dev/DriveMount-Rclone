param(
    [string]$DriveLetter = 'Z:'
)

$ErrorActionPreference = 'Stop'

$driveName = $DriveLetter.TrimEnd(':')
$mappedDrive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue

if (-not $mappedDrive) {
    Write-Host "$DriveLetter is not mapped."
    return
}

Write-Host "Removing $DriveLetter mapping..."
net use $DriveLetter /delete /y | Out-Null

if ($LASTEXITCODE -eq 0) {
    Remove-PSDrive -Name $driveName -Force -ErrorAction SilentlyContinue
    Write-Host "$DriveLetter removed."
    return
}

throw "Failed to remove $DriveLetter"
