param(
    [string]$DriveLetter = 'Z:',
    [string]$WebDavUrl = 'http://localhost:8080/'
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'Checking WebClient service...'
$service = Get-Service -Name WebClient -ErrorAction SilentlyContinue
if (-not $service) {
    throw 'WebClient service not found.'
}

if ($service.Status -ne 'Running') {
    Start-Service -Name WebClient
    Write-Host 'WebClient service started'
} else {
    Write-Host 'WebClient already running'
}

Write-Host ''
Write-Host 'Checking listener 127.0.0.1:8080...'
$listener = Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort 8080 -ErrorAction SilentlyContinue
if (-not $listener) {
    throw '127.0.0.1:8080 is DOWN'
}
Write-Host '127.0.0.1:8080 is UP'

Write-Host ''
Write-Host "Checking if $DriveLetter already mapped..."
$drive = Get-PSDrive -Name ($DriveLetter.TrimEnd(':')) -ErrorAction SilentlyContinue
if ($drive) {
    if ($drive.DisplayRoot -eq '\\localhost@8080\DavWWWRoot') {
        Write-Host "$DriveLetter already exists. Exiting."
        return
    }

    throw "$DriveLetter already exists but points to '$($drive.DisplayRoot)'."
}

Write-Host ''
Write-Host "Mapping $DriveLetter drive..."
net use $DriveLetter $WebDavUrl /user:ignored ignored /persistent:yes | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "$DriveLetter successfully mapped"
    return
}

throw "$DriveLetter mapping failed"
