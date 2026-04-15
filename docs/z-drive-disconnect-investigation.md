# Z drive disconnect investigation

Created: 12:04:2026 14:05
Updated: 13:04:2026 17:35

## Objective

Record the current investigation into why `Z:` disappears even though a watchdog exists on this machine.

## Scope

- `D:\Projects\Systems\DriveMount-Rclone` scripts and docs
- read-only inspection of the active workstation runtime state
- read-only inspection of the legacy scheduled-task scripts under `D:\tools\Mount-Rclone`

## Executive Summary

- The active watchdog does exist, but it does not run from this repo.
- The machine is still using legacy scheduled tasks that point to `D:\tools\Mount-Rclone`.
- The recurring keep-alive task detects the broken mount and repeatedly tries to repair it.
- Every repair attempt currently fails because the task cannot start the `WebClient` service in its current context.
- The local `rclone serve webdav` listener can stay healthy while `Z:` is gone, so listener health alone is not enough to prove the stack is usable.

## Confirmed Evidence

### Repo design and documented boundaries

- `docs\tasks-plan.md` states that this repo does not create real scheduled tasks in V1.
- `docs\setup-and-usage.md` documents `start-z-drive.ps1` as the preferred wrapper and lists scheduled-task creation and repair under "What is not automated yet".
- `scripts\start-z-drive.ps1` is a one-shot start wrapper. It starts WebDAV, maps `Z:`, verifies once, and exits.
- `scripts\test-z-drive-stack.ps1` is read-only. It reports state but does not repair anything.

### Current machine state at investigation time

- `.\scripts\test-z-drive-stack.ps1` reported:
  - `RcloneExe: OK`
  - `RemoteConfigured: OK`
  - `WebClientRunning: FAIL`
  - `ListenerActive: OK`
  - `ListenerOwnedByProject: OK`
  - `DriveVisibleInShell: FAIL`
  - `DrivePointsToExpectedRoot: FAIL`
- `net use` returned no active mappings.
- `Get-NetTCPConnection` still showed a listener on `127.0.0.1:8080`.
- The listener process command line matched `rclone.exe serve webdav rclone-google: --addr 127.0.0.1:8080 ...`.

### Active scheduled-task surface

- Scheduled task `Serve Rclone WebDAV` runs:
  - `powershell.exe -File "D:\tools\Mount-Rclone\start-rclone-z-drive.ps1"`
- Scheduled task `Z Drive Keep Alive` runs:
  - `powershell.exe -File "D:\tools\Mount-Rclone\keep-z-drive-alive.ps1"`
- Both tasks currently report `LastTaskResult = 1`.
- `Z Drive Keep Alive` is the actual recurring watchdog. It checks listener state, mapping state, drive visibility, and a directory probe before deciding whether to rerun bootstrap or remap only.

### Repair failure captured in runtime logs

- `D:\tools\Mount-Rclone\logs\z-drive-keepalive.log` shows repeated failures at 5-minute intervals.
- Those entries consistently show:
  - `ListenerUp = true`
  - `MappingPresent = false`
  - `DriveVisible = false`
  - `RepairAction = map`
  - `RepairSucceeded = false`
- The repeated repair failure reason is:
  - `Service 'WebClient (WebClient)' cannot be started due to the following error: Cannot open WebClient service on computer '.'.`
- `D:\tools\Mount-Rclone\logs\rclone.log` shows the WebDAV listener itself continuing normally during the same window.

## Root Cause

The disconnect behavior is currently explained by a three-part mismatch:

1. The live scheduled tasks still target the legacy tree at `D:\tools\Mount-Rclone`, not the documented V1 wrapper in this repo.
2. The recurring watchdog does notice that `Z:` is broken, but its repair step fails because it cannot start `WebClient` from the current task context.
3. This repo's V1 wrapper is intentionally a startup chain, not a persistent supervisor, so once `Z:` disappears later there is no repo-native background process that rebinds it.

## What This Means Operationally

- The current failure is not "rclone died".
- The current failure is not "the watchdog never ran".
- The current failure is that the watchdog ran, detected the break, and then failed at the `WebClient` gate before `net use` could recreate `Z:`.
- As long as the task context cannot start `WebClient`, the recurring keep-alive loop will continue to fail in the same way.

## Manual Recovery Result

A manual recovery pass from this repo succeeded once `WebClient` was started in the same interactive context:

- `.\scripts\start-z-drive.ps1` completed successfully
- `.\scripts\map-z-drive.ps1` showed `Z:` mapped to `\\localhost@8080\DavWWWRoot`
- `net use` then showed:
  - `Z:        \\localhost@8080\DavWWWRoot`
- `cmd /c dir Z:\` returned a normal directory listing
- `.\scripts\test-z-drive-stack.ps1` then reported `All checks passed.`

This confirms the current stack can still be restored manually. It does not remove the underlying scheduled-task drift or the `WebClient` startup problem in the legacy keep-alive path.

## Permanent Fix Applied

With explicit user approval, the live scheduled-task surface on this machine was repaired.

### Task changes

- Backups were exported to:
  - `D:\Projects\Systems\DriveMount-Rclone\logs\task-backups-20260412-1415\Serve_Rclone_WebDAV.xml`
  - `D:\Projects\Systems\DriveMount-Rclone\logs\task-backups-20260412-1415\Z_Drive_Keep_Alive.xml`
- `Serve Rclone WebDAV` now runs:
  - `powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive.ps1"`
- `Z Drive Keep Alive` now runs the same repo wrapper:
  - `powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive.ps1"`
- Both tasks now run with:
  - `LogonType = Interactive`
  - `RunLevel = Highest`
- Both tasks now launch through:
  - `wscript.exe "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive-hidden.vbs"`
- The hidden launcher then runs:
  - `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive.ps1"`
- This removed the visible console-window flashing that still occurred with direct `powershell.exe -WindowStyle Hidden` task actions.

### Important note

- `EnableLinkedConnections = 1` was already present under:
  - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`
- That meant the needed task-side fix was task retargeting plus privilege level, not a new registry change.
- An intermediate keep-alive failure after retargeting was caused by an invalid task argument form:
  - `-UseTranscript:$false`
- That argument was removed. The keep-alive task now uses the same proven action string as the logon task.

## End-to-End Verification After Task Repair

The repaired keep-alive path was verified with a controlled recovery test:

1. `Z:` was unmapped with `scripts\unmap-z-drive.ps1`
2. `WebClient` was stopped
3. `Z Drive Keep Alive` was started on demand via Task Scheduler
4. The task restored:
   - `WebClient = Running`
   - `Z: = \\localhost@8080\DavWWWRoot`
5. `.\scripts\test-z-drive-stack.ps1` then reported `All checks passed.`
6. `Get-ScheduledTaskInfo -TaskName 'Z Drive Keep Alive'` reported `LastTaskResult = 0`

## Hidden Launch Verification

On 13 April 2026 the live tasks were switched from direct `powershell.exe` actions to the hidden `wscript.exe` launcher wrapper.

- Verified task action for `Serve Rclone WebDAV`:
  - `wscript.exe "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive-hidden.vbs"`
- Verified task action for `Z Drive Keep Alive`:
  - `wscript.exe "D:\Projects\Systems\DriveMount-Rclone\scripts\start-z-drive-hidden.vbs"`
- Repeated the controlled break-and-recover test after the launcher swap:
  - unmap `Z:`
  - stop `WebClient`
  - start `Z Drive Keep Alive`
  - confirm `WebClient = Running`
  - confirm `Z: = \\localhost@8080\DavWWWRoot`
  - confirm `All checks passed.`

## Repo-local Note

During this investigation, `scripts\start-z-drive.ps1` was corrected to dot-source `DriveMount-Rclone.common.ps1` before calling shared helper functions.

That bug did not cause the live disconnect on this machine, because the active scheduled tasks were not using this repo. It still needed fixing so the documented V1 wrapper is usable when the task surface is eventually retargeted here.

## Validation Performed

- Read-only doc review:
  - `README.md`
  - `docs\architecture.md`
  - `docs\setup-and-usage.md`
  - `docs\known-risks-and-open-questions.md`
  - `docs\tasks-plan.md`
- Read-only script review:
  - `scripts\DriveMount-Rclone.common.ps1`
  - `scripts\start-z-drive.ps1`
  - `scripts\serve-rclone-google.ps1`
  - `scripts\map-z-drive.ps1`
  - `scripts\test-z-drive-stack.ps1`
  - `D:\tools\Mount-Rclone\start-rclone-z-drive.ps1`
  - `D:\tools\Mount-Rclone\keep-z-drive-alive.ps1`
  - `D:\tools\Mount-Rclone\map-z-drive.ps1`
- Read-only runtime checks:
  - `.\scripts\test-z-drive-stack.ps1`
  - `Get-ScheduledTask` and `Get-ScheduledTaskInfo` for `Serve Rclone WebDAV` and `Z Drive Keep Alive`
  - `Get-NetTCPConnection -LocalPort 8080`
  - `net use`
  - log tail checks for:
    - `D:\tools\Mount-Rclone\logs\z-drive-keepalive.log`
    - `D:\tools\Mount-Rclone\logs\rclone.log`
- Narrow code validation:
  - PowerShell parser check for `scripts\start-z-drive.ps1`
- Manual recovery validation:
  - `.\scripts\start-z-drive.ps1`
  - `.\scripts\map-z-drive.ps1`
  - `cmd /c dir Z:\`
  - `.\scripts\test-z-drive-stack.ps1`
- Live scheduled-task repair validation:
  - exported task XML backups before changing tasks
  - verified task actions, principals, and run levels after update
  - controlled recovery test by unmapping `Z:` and stopping `WebClient`
  - `Start-ScheduledTask -TaskName 'Z Drive Keep Alive'`
  - `Get-ScheduledTaskInfo` result check after task run
- Hidden launcher validation:
  - verified both task actions now use `wscript.exe`
  - repeated the same controlled recovery test after the launcher swap

## Current Status

- `rclone` WebDAV listener is up.
- `WebClient` is running.
- `Z:` is currently mapped to `\\localhost@8080\DavWWWRoot`.
- `.\scripts\test-z-drive-stack.ps1` currently passes.
- The live tasks now point to `D:\Projects\Systems\DriveMount-Rclone` instead of `D:\tools\Mount-Rclone`.
- The live keep-alive task has been verified to recover a broken mount/service state on demand.
- The live tasks now launch through a hidden `wscript.exe` wrapper instead of a visible `powershell.exe` console action.

## Recommended Next Step

Watch the next unattended scheduled run and confirm that `Z:` still survives normal session churn without manual intervention. If a later failure appears, the next debugging target is Task Scheduler runtime context rather than the repo wrapper or rclone listener itself.
