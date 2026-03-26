# Setup and usage

## Prerequisites

- Windows
- PowerShell
- `winget` available if you want the bootstrap script to install `rclone`
- `rclone.exe` available through `PATH` or a known local install location
- an existing rclone remote named `rclone-google:`
- Windows WebClient service available

## Fresh machine path

If this is a new machine or the local rclone install is missing, use:

```powershell
.\scripts\bootstrap-z-drive.ps1
```

That bootstrap path will:

- try to find `rclone.exe` through `PATH` or known local install locations
- install rclone with `winget` if needed and allowed
- launch the rclone config wizard if the `rclone-google:` remote is missing
- start the WebClient service if needed
- start the stack and map `Z:`

## Recommended run order

1. `scripts\start-z-drive.ps1`
2. `scripts\test-z-drive-stack.ps1`
3. `scripts\unmap-z-drive.ps1` when you want to detach the drive

## Common commands

```powershell
.\scripts\bootstrap-z-drive.ps1
.\scripts\start-z-drive.ps1
.\scripts\test-z-drive-stack.ps1
.\scripts\unmap-z-drive.ps1
.\scripts\stop-z-drive.ps1
```

## What the wrapper does

`start-z-drive.ps1` is the preferred path because it:

- starts the WebDAV serving layer if needed
- waits for `127.0.0.1:8080`
- maps `Z:`
- writes a wrapper transcript log

`bootstrap-z-drive.ps1` is the preferred path for a fresh machine because it can also handle install and remote setup in one pass.

Both scripts use the shared runtime defaults from `scripts\DriveMount-Rclone.common.ps1`, so the expected drive root, remote name, and localhost endpoint stay aligned.

## Runtime expectations

- `Z:` is the documented V1 drive letter.
- `127.0.0.1:8080` is the documented WebDAV endpoint.
- `rclone-google:` is the expected remote name.
- Logs are written only to `logs\`.

## How to test

Use the read-only test script:

```powershell
.\scripts\test-z-drive-stack.ps1
```

It checks:

- whether `rclone.exe` is available
- whether the `rclone-google:` remote exists
- whether `WebClient` is running
- whether `127.0.0.1:8080` is listening
- whether that listener is owned by the expected project `rclone serve webdav` process
- whether `Z:` is visible in the current session

## How to read logs

- wrapper logs live in `logs\start-z-drive-*.log`
- rclone logs live in `logs\rclone.log`

If `Z:` does not appear, check the wrapper log first.
If the wrapper says WebDAV is up but mapping still fails, check the rclone log for WebDAV or auth errors.

## Common recovery cases

- `rclone.exe not found`
  - rclone is missing from PATH or the local install is broken.
- `localhost:8080 is DOWN`
  - the WebDAV process did not start or exited early.
- `Z: mapping failed`
  - WebClient may be unavailable, the endpoint may not be ready, or another mapping may already exist.
- `Z:` exists in Explorer but not in the current shell
  - refresh the session or rerun the wrapper in the same user context.

## What is not automated yet

- scheduled task creation
- scheduled task repair
- auto-push to GitHub
- auto-repair of auth tokens
- remote re-auth flow
