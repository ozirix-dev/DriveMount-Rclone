# Command reference

This is the shortest path to the scripts in this repo.

## Operator commands

| Script | Purpose | State change |
| --- | --- | --- |
| `scripts\bootstrap-z-drive.ps1` | Install/configure prerequisites and start | Yes |
| `scripts\start-z-drive.ps1` | Start WebDAV and map `Z:` | Yes |
| `scripts\serve-rclone-google.ps1` | Start the rclone WebDAV listener | Yes |
| `scripts\map-z-drive.ps1` | Map `Z:` to localhost WebDAV | Yes |
| `scripts\test-z-drive-stack.ps1` | Check stack health | No |
| `scripts\unmap-z-drive.ps1` | Remove the `Z:` mapping | Yes |
| `scripts\stop-z-drive.ps1` | Stop the project WebDAV process | Yes |

## Common sequence

```powershell
.\scripts\bootstrap-z-drive.ps1
.\scripts\start-z-drive.ps1
.\scripts\test-z-drive-stack.ps1
.\scripts\unmap-z-drive.ps1
```

## Troubleshooting focus

- If `Z:` is missing, check `logs\start-z-drive-*.log` first.
- If WebDAV is up but mapping fails, check `logs\rclone.log`.
- If the endpoint is already running, `serve-rclone-google.ps1` should exit cleanly instead of spawning duplicates.
