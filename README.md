# DriveMount-Rclone

Windows infra and automation project for mounting Google Drive via rclone WebDAV as drive `Z:`.

This repo is a clean local-first V1 for:

- starting the rclone WebDAV serving layer
- mapping the WebDAV endpoint to `Z:`
- checking whether the stack is healthy
- unmapping and stopping the stack safely
- keeping machine-local logs out of git

## What this solves

The practical goal is a stable local drive letter backed by Google Drive through rclone and Windows WebDAV.

The preferred operator path is:

`start-z-drive.ps1`

That wrapper is meant to do the normal startup sequence in one place instead of relying on scattered manual steps.

## Basic flow

1. `serve-rclone-google.ps1` starts `rclone serve webdav` on `127.0.0.1:8080`.
2. `map-z-drive.ps1` maps `Z:` to `http://localhost:8080/`.
3. `test-z-drive-stack.ps1` checks the stack without changing state.
4. `unmap-z-drive.ps1` removes the `Z:` mapping.
5. `stop-z-drive.ps1` stops the project-controlled rclone WebDAV process.

## What is in scope

- Windows + PowerShell automation
- local drive-letter mapping
- local logs and troubleshooting
- GitHub-ready repo structure

## What is out of scope for V1

- new app features
- scheduled task management in this round
- machine-wide configuration changes beyond what the scripts themselves already need at runtime
- generalized multi-cloud abstraction
- destructive cleanup of unrelated files

## Local vs GitHub

This repo is intended to be usable locally first.
GitHub is the source of truth for versioned project state, but local scripts remain the immediate operator tool.

Machine-local state such as rclone auth tokens, Windows network mappings, and runtime logs stays outside git.

## Safety

Safe to run:

- `scripts\test-z-drive-stack.ps1`
- `scripts\start-z-drive.ps1`
- `scripts\unmap-z-drive.ps1`

Potentially state-changing:

- `scripts\serve-rclone-google.ps1`
- `scripts\map-z-drive.ps1`
- `scripts\stop-z-drive.ps1`

## Logs

Runtime logs live in `logs\`.

- wrapper logs: timestamped `start-z-drive-*.log`
- rclone logs: `logs\rclone.log`

Logs are ignored by git on purpose.

## Status

This is a V1 bootstrap.
The repo is intentionally small and focused so it can be turned into a separate GitHub project cleanly later.
