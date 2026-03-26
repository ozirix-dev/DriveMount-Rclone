# Tasks plan

This repo does not create real scheduled tasks in V1.

## Preferred future model

One primary scheduled task should eventually run:

- `scripts\start-z-drive.ps1`

That is the recommended long-term entrypoint because it handles the normal startup chain in one place.

## Optional later tasks

- `scripts\unmap-z-drive.ps1`
- `scripts\test-z-drive-stack.ps1`
- `scripts\stop-z-drive.ps1`

These are useful later, but they should stay secondary to the main wrapper.

## Why not scattered tasks

Two unrelated logon tasks are not ideal long term because they can drift out of sync:

- one task may start WebDAV
- another task may fail to map the drive
- failures become harder to diagnose

The wrapper model keeps the startup sequence explicit and easier to troubleshoot.
