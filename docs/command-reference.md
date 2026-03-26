# Command reference

This is the shortest path to the scripts in this repo.

## Operator commands

| Script | Purpose | State change |
| --- | --- | --- |
| `scripts\bootstrap-z-drive.ps1` | Install/configure prerequisites and start | Yes |
| `scripts\start-z-drive.ps1` | Start WebDAV and map `Z:` | Yes |
| `scripts\serve-rclone-google.ps1` | Start the rclone WebDAV listener | Yes |
| `scripts\map-z-drive.ps1` | Map `Z:` to localhost WebDAV | Yes |
| `scripts\test-z-drive-stack.ps1` | Check stack health and listener ownership | No |
| `scripts\unmap-z-drive.ps1` | Remove the `Z:` mapping | Yes |
| `scripts\stop-z-drive.ps1` | Stop the project-owned WebDAV process | Yes |

## Troubleshooting focus

- If `Z:` is missing, check `logs\start-z-drive-*.log` first.
- If WebDAV is up but mapping fails, check `logs\rclone.log`.
- If the endpoint is already running, `serve-rclone-google.ps1` should exit cleanly instead of spawning duplicates.
- If `stop-z-drive.ps1` refuses to stop, the listener does not match the expected project command line.
- If you plan to share logs publicly, review them first because they may contain local environment details.
