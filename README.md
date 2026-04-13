# DriveMount-Rclone

Windows infra and automation project for mounting Google Drive via rclone WebDAV as drive `Z:`.

This is a small, local-first V1.

- the repo contains scripts and docs
- machine-local auth state, drive mappings, and runtime logs stay outside git
- `scripts\DriveMount-Rclone.common.ps1` is the source of truth for runtime defaults
- the project is intentionally narrow, not a general-purpose sync framework

## At a glance

V1 defaults are fixed on purpose:

- remote: `rclone-google:`
- drive: `Z:`
- listener: `127.0.0.1:8080`
- WebDAV URL: `http://localhost:8080/`
- expected mapped root: `\\localhost@8080\DavWWWRoot`

## Quick Start

Fresh machine or first-time setup:

```powershell
.\scripts\bootstrap-z-drive.ps1
```

Daily start:

```powershell
.\scripts\start-z-drive.ps1
.\scripts\test-z-drive-stack.ps1
```

If you need to detach the drive:

```powershell
.\scripts\unmap-z-drive.ps1
```

To stop the local WebDAV listener too:

```powershell
.\scripts\stop-z-drive.ps1
```

## What success looks like

After a successful run, you should see:

- `start-z-drive.ps1` finishes the normal startup sequence
- `test-z-drive-stack.ps1` reports `All checks passed.`
- the listener is up on `127.0.0.1:8080`
- `Z:` is visible in the current session
- `Z:` points to `\\localhost@8080\DavWWWRoot`
- wrapper logs are written to `logs\start-z-drive-*.log`
- rclone logs are written to `logs\rclone.log`

## Script Map

- `scripts\bootstrap-z-drive.ps1` installs or configures prerequisites, then starts the stack
- `scripts\start-z-drive.ps1` boots the full stack
- `scripts\start-z-drive-hidden.vbs` is the hidden scheduled-task launcher for `start-z-drive.ps1`
- `scripts\serve-rclone-google.ps1` starts the WebDAV serving layer
- `scripts\map-z-drive.ps1` maps `Z:`
- `scripts\test-z-drive-stack.ps1` performs read-only checks
- `scripts\unmap-z-drive.ps1` removes `Z:`
- `scripts\stop-z-drive.ps1` stops the project-controlled WebDAV process

## Recommended Operator Flow

For normal use:

1. run `scripts\start-z-drive.ps1`
2. run `scripts\test-z-drive-stack.ps1`
3. work from `Z:`
4. run `scripts\unmap-z-drive.ps1` when you want to detach the drive
5. run `scripts\stop-z-drive.ps1` only if you want to stop the local WebDAV listener itself

`scripts\bootstrap-z-drive.ps1` is the first-run path when rclone, the remote, or WebClient need setup.

## When this fits well

This stack fits when you want:

- a stable local drive letter backed by Google Drive through rclone and Windows WebDAV
- a small, explicit operator flow instead of scattered manual steps
- a repo that keeps machine-local state out of version control
- a setup suited to larger files and archive-style workflows

It is a weaker fit when you need:

- lots of tiny files copied in large volumes
- immediate delete visibility in the mounted folder view
- a generic multi-cloud layer
- a replacement for a broader sync platform

## Local vs GitHub

This repo is local-first.
GitHub is the source of truth for versioned project state, while local scripts remain the operator tool.

The repo does not contain Google credentials, tokens, or its own auth layer.
Machine-local state such as the rclone remote, auth tokens, Windows network mappings, and runtime logs stays outside git.
If the remote is missing, bootstrap can open the interactive `rclone config` wizard locally.
Remote re-auth is still a local manual step; it is not automated in V1.

## Safety

Safe to run:

- `scripts\test-z-drive-stack.ps1`
- `scripts\start-z-drive.ps1`
- `scripts\unmap-z-drive.ps1`

Potentially state-changing:

- `scripts\bootstrap-z-drive.ps1`
- `scripts\serve-rclone-google.ps1`
- `scripts\map-z-drive.ps1`
- `scripts\stop-z-drive.ps1`

## Logs

Runtime logs live in `logs\`.

- wrapper logs: timestamped `start-z-drive-*.log`
- rclone logs: `logs\rclone.log`

Logs are ignored by git on purpose.
Logs are machine-local output and may include local environment details.
Do not share log files publicly without reviewing them first.

## Docs

- `docs\architecture.md`
- `docs\bootstrap-and-install.md`
- `docs\setup-and-usage.md`
- `docs\command-reference.md`
- `docs\tasks-plan.md`
- `docs\known-risks-and-open-questions.md`
- `docs\z-drive-disconnect-investigation.md`
- `SECURITY.md`

## Status

This repo is intentionally small, focused, and public-safe.
It is a documented solution for one Windows mount setup, not a general-purpose sync framework.

License: MIT. See [LICENSE](LICENSE).
