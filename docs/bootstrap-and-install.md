# Bootstrap and install

This page describes the one-pass setup path for a fresh Windows machine.

## Primary command

```powershell
.\scripts\bootstrap-z-drive.ps1
```

Optional skip flags:

- `-NoInstall`
- `-NoRemoteConfig`
- `-NoStart`

## What it tries to do

1. Find an existing `rclone.exe` from `PATH` or known local install locations.
2. Install rclone with `winget` if it is missing and installation is allowed.
3. Verify that the `rclone-google:` remote exists.
4. Launch the rclone config wizard if the remote is missing and configuration is allowed.
5. Start the WebClient service if it is not already running.
6. Start the stack and map `Z:`.

The bootstrap path uses the same runtime defaults as the normal operator scripts.

## What it does not try to hide

- Remote auth still needs a real Google account and user consent.
- If `rclone-google:` is not configured yet, the config wizard is still interactive.
- If `winget` is missing, rclone installation cannot be automated.
- `Z:` and `127.0.0.1:8080` remain the default V1 values.
- The local expected drive root is derived from the shared runtime settings, so bootstrap and start stay aligned.

## After bootstrap

Once bootstrap finishes, use the normal daily commands:

```powershell
.\scripts\test-z-drive-stack.ps1
.\scripts\unmap-z-drive.ps1
.\scripts\stop-z-drive.ps1
```

## Why this exists

The old setup was split across separate steps.
This bootstrap path makes the project easier to adopt on a fresh machine without manually stitching the pieces together.
