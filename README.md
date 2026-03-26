# DriveMount-Rclone

Windows infra and automation project for mounting Google Drive via rclone WebDAV as drive `Z:`.

This repo is a clean local-first V1 for:

- starting the rclone WebDAV serving layer
- mapping the WebDAV endpoint to `Z:`
- checking whether the stack is healthy
- unmapping and stopping the stack safely
- keeping machine-local logs out of git
- keeping runtime defaults centralized in `scripts\DriveMount-Rclone.common.ps1`

## Quick Start

Fresh machine or first-time setup:

```powershell
.\scripts\bootstrap-z-drive.ps1
```

Normal day-to-day start:

```powershell
.\scripts\start-z-drive.ps1
.\scripts\test-z-drive-stack.ps1
```

If you need to detach the drive:

```powershell
.\scripts\unmap-z-drive.ps1
```

## What this solves

The practical goal is a stable local drive letter backed by Google Drive through rclone and Windows WebDAV.

The preferred operator path is `start-z-drive.ps1`.

That wrapper performs the normal startup sequence in one place instead of relying on scattered manual steps.
It uses the same runtime defaults and expected-state checks as the bootstrap, test, and stop scripts.

## Script Map

- `scripts\bootstrap-z-drive.ps1` installs or configures prerequisites, then starts the stack
- `scripts\start-z-drive.ps1` boots the full stack
- `scripts\serve-rclone-google.ps1` starts the WebDAV serving layer
- `scripts\map-z-drive.ps1` maps `Z:`
- `scripts\test-z-drive-stack.ps1` performs read-only checks
- `scripts\unmap-z-drive.ps1` removes `Z:`
- `scripts\stop-z-drive.ps1` stops the project-controlled WebDAV process

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

The repo does not contain Google credentials, tokens, or an auth layer of its own.
Machine-local state such as the rclone remote, auth tokens, Windows network mappings, and runtime logs stays outside git.
If the remote is missing, bootstrap can open the interactive `rclone config` wizard on the local machine.
Remote re-auth is still a local manual step; it is not automated in V1.

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
Logs are machine-local runtime output and may include local environment details.
Do not share log files publicly without reviewing them first.

## Docs

- `docs\architecture.md`
- `docs\bootstrap-and-install.md`
- `docs\setup-and-usage.md`
- `docs\command-reference.md`
- `docs\tasks-plan.md`
- `docs\known-risks-and-open-questions.md`
- `SECURITY.md`

## Status

This is a V1 bootstrap with a light V2 cleanup on top.
The repo is intentionally small and focused so it can be turned into a separate GitHub project cleanly later.
