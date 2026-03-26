function Resolve-DriveMountRcloneExecutable {
    param(
        [string]$ExecutableName = 'rclone.exe'
    )

    $command = Get-Command $ExecutableName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\rclone.exe'),
        'C:\Program Files\Rclone\rclone.exe',
        'C:\Program Files (x86)\Rclone\rclone.exe'
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Test-DriveMountRcloneRemoteConfigured {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RclonePath,

        [Parameter(Mandatory = $true)]
        [string]$RemoteName
    )

    if ([string]::IsNullOrWhiteSpace($RclonePath) -or -not (Test-Path $RclonePath)) {
        return $false
    }

    try {
        $remoteList = & $RclonePath listremotes 2>$null
        return $remoteList -contains $RemoteName
    }
    catch {
        return $false
    }
}

function Test-DriveMountRcloneListener {
    param(
        [int]$ListenPort = 8080
    )

    return [bool](Get-NetTCPConnection -State Listen -LocalAddress '127.0.0.1' -LocalPort $ListenPort -ErrorAction SilentlyContinue)
}

function Ensure-DriveMountRcloneLogDirectory {
    param(
        [string]$ProjectRoot
    )

    $logDir = Join-Path $ProjectRoot 'logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    return $logDir
}
