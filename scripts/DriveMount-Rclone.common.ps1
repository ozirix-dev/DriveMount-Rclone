function Get-DriveMountRcloneRuntimeSettings {
    param(
        [hashtable]$Overrides = @{}
    )

    if ($null -eq $Overrides) {
        $Overrides = @{}
    }

    $settings = [ordered]@{
        RemoteName = 'rclone-google:'
        DriveLetter = 'Z:'
        ListenPort = 8080
        ListenAddress = $null
        WebDavUrl = $null
        ExpectedDisplayRoot = $null
        LogDirectoryName = 'logs'
        RcloneLogFileName = 'rclone.log'
    }

    foreach ($key in @($settings.Keys)) {
        if (-not $Overrides.ContainsKey($key)) {
            continue
        }

        $value = $Overrides[$key]
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $settings[$key] = $value
    }

    try {
        $settings.ListenPort = [int]$settings.ListenPort
    }
    catch {
        throw "ListenPort must be an integer between 1 and 65535."
    }

    if ($settings.ListenPort -lt 1 -or $settings.ListenPort -gt 65535) {
        throw "ListenPort must be an integer between 1 and 65535."
    }

    $settings.RemoteName = [string]$settings.RemoteName
    $settings.DriveLetter = [string]$settings.DriveLetter
    $settings.DriveLetter = $settings.DriveLetter.Trim().ToUpperInvariant()
    $settings.RemoteName = $settings.RemoteName.Trim()

    if ([string]::IsNullOrWhiteSpace($settings.RemoteName) -or -not $settings.RemoteName.EndsWith(':')) {
        throw "RemoteName must end with ':' and cannot be blank."
    }

    if ($settings.DriveLetter -notmatch '^[A-Z]:$') {
        throw "DriveLetter must look like 'Z:'."
    }

    if ([string]::IsNullOrWhiteSpace($settings.ListenAddress)) {
        $settings.ListenAddress = ('127.0.0.1:{0}' -f $settings.ListenPort)
    }
    else {
        $settings.ListenAddress = $settings.ListenAddress.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($settings.WebDavUrl)) {
        $settings.WebDavUrl = ('http://localhost:{0}/' -f $settings.ListenPort)
    }
    else {
        $settings.WebDavUrl = $settings.WebDavUrl.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($settings.ExpectedDisplayRoot)) {
        $settings.ExpectedDisplayRoot = ('\\localhost@{0}\DavWWWRoot' -f $settings.ListenPort)
    }
    else {
        $settings.ExpectedDisplayRoot = $settings.ExpectedDisplayRoot.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($settings.LogDirectoryName)) {
        $settings.LogDirectoryName = 'logs'
    }
    else {
        $settings.LogDirectoryName = $settings.LogDirectoryName.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($settings.RcloneLogFileName)) {
        $settings.RcloneLogFileName = 'rclone.log'
    }
    else {
        $settings.RcloneLogFileName = $settings.RcloneLogFileName.Trim()
    }

    return [pscustomobject]$settings
}

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

function Test-DriveMountRcloneWebDavCommandLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLine,

        [Parameter(Mandatory = $true)]
        [psobject]$RuntimeSettings
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    return (
        $CommandLine -match 'rclone' -and
        $CommandLine -match 'serve' -and
        $CommandLine -match 'webdav' -and
        $CommandLine -match [regex]::Escape($RuntimeSettings.RemoteName) -and
        $CommandLine -match [regex]::Escape($RuntimeSettings.ListenAddress)
    )
}

function Get-DriveMountRcloneWebDavListenerState {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RuntimeSettings
    )

    $state = [ordered]@{
        ListenPort = $RuntimeSettings.ListenPort
        ListenAddress = $RuntimeSettings.ListenAddress
        RemoteName = $RuntimeSettings.RemoteName
        ListenerActive = $false
        ProcessOwnedByProject = $false
        ProcessId = $null
        CommandLine = $null
        Reason = "No listener found on $($RuntimeSettings.ListenAddress)."
    }

    $listener = Get-NetTCPConnection -State Listen -LocalPort $RuntimeSettings.ListenPort -ErrorAction SilentlyContinue
    if (-not $listener) {
        return [pscustomobject]$state
    }

    $state.ListenerActive = $true
    $state.ProcessId = $listener.OwningProcess

    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)" -ErrorAction SilentlyContinue
    if (-not $process) {
        $state.Reason = "Could not inspect process for PID $($listener.OwningProcess)."
        return [pscustomobject]$state
    }

    $state.CommandLine = $process.CommandLine
    if (Test-DriveMountRcloneWebDavCommandLine -CommandLine $process.CommandLine -RuntimeSettings $RuntimeSettings) {
        $state.ProcessOwnedByProject = $true
        $state.Reason = "Expected rclone WebDAV listener detected on $($RuntimeSettings.ListenAddress)."
    }
    else {
        $state.Reason = "Listener on $($RuntimeSettings.ListenAddress) is not the expected project process."
    }

    return [pscustomobject]$state
}

function Test-DriveMountRcloneDriveMappingState {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$RuntimeSettings
    )

    $driveName = $RuntimeSettings.DriveLetter.TrimEnd(':')
    $drive = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue

    return [pscustomobject]@{
        DriveLetter = $RuntimeSettings.DriveLetter
        ExpectedDisplayRoot = $RuntimeSettings.ExpectedDisplayRoot
        ActualDisplayRoot = if ($drive) { $drive.DisplayRoot } else { $null }
        DriveVisibleInShell = [bool]$drive
        DrivePointsToExpectedRoot = [bool]($drive -and $drive.DisplayRoot -eq $RuntimeSettings.ExpectedDisplayRoot)
        Drive = $drive
    }
}

function Ensure-DriveMountRcloneLogDirectory {
    param(
        [string]$ProjectRoot,
        [string]$LogDirectoryName = 'logs'
    )

    $logDir = Join-Path $ProjectRoot $LogDirectoryName
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    return $logDir
}
